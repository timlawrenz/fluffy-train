# frozen_string_literal: true

require 'gl_command'

module Scheduling
  module Strategies
    class CuratorsChoice < GLCommand::Callable
      requires persona: Persona
      returns :selected_photo

      def call
        photo = find_highest_rated_unposted_photo

        if photo.nil?
          handle_no_photo_found
        else
          handle_photo_found(photo)
        end
      end

      private

      def handle_no_photo_found
        message = "No unposted photos found for curator's choice strategy for persona: #{persona.name}"
        Rails.logger.warn(message)
        context.selected_photo = nil
      end

      def handle_photo_found(photo)
        # Immediately create a Scheduling::Post record with status 'posting'
        post = create_posting_record(photo)

        if post.persisted?
          # Attempt to post to Instagram
          handle_instagram_posting(post, photo)
          context.selected_photo = photo
        else
          message = "Failed to create posting record for photo #{photo.id}"
          Rails.logger.error(message)
          context.selected_photo = nil
        end
      end

      def find_highest_rated_unposted_photo
        # Find photos for this persona that don't have an associated Scheduling::Post
        # Join with photo_analyses and order by aesthetic_score descending
        persona.photos
               .joins(:photo_analysis)
               .where.not(id: posted_photo_ids_for_persona)
               .order('photo_analyses.aesthetic_score DESC NULLS LAST')
               .first
      end

      def posted_photo_ids_for_persona
        Scheduling::Post.where(persona: persona).pluck(:photo_id)
      end

      def create_posting_record(photo)
        Scheduling::Post.create(
          photo: photo,
          persona: persona,
          caption: photo.photo_analysis&.caption,
          status: 'posting'
        )
      end

      def handle_instagram_posting(post, photo)
        # Generate public URL for the photo
        public_url_result = generate_public_photo_url(photo)

        if public_url_result.success?
          post_to_instagram(post, photo, public_url_result.public_photo_url)
        else
          mark_post_failed(post, photo, "URL generation failed: #{public_url_result.errors.join(', ')}")
        end
      rescue StandardError => e
        mark_post_failed(post, photo, "Unexpected error: #{e.message}")
      end

      def post_to_instagram(post, photo, public_photo_url)
        instagram_result = send_to_instagram(post, public_photo_url)

        if instagram_result.success?
          update_post_as_posted(post, instagram_result.instagram_post_id)
        else
          mark_post_failed(post, photo, "Instagram posting failed: #{instagram_result.errors.join(', ')}")
        end
      end

      def update_post_as_posted(post, provider_post_id)
        post.update!(
          provider_post_id: provider_post_id,
          posted_at: Time.current
        )
        post.mark_as_posted!
      end

      def mark_post_failed(post, photo, error_message)
        post.mark_as_failed!
        Rails.logger.error("Posting failed for photo #{photo.id}: #{error_message}")
      end

      def generate_public_photo_url(photo)
        Scheduling::Commands::GeneratePublicPhotoUrl.call(photo: photo)
      end

      def send_to_instagram(post, public_photo_url)
        Scheduling::Commands::SendPostToInstagram.call(
          public_photo_url: public_photo_url,
          caption: post.caption,
          persona: persona
        )
      end
    end
  end
end
