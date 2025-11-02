# frozen_string_literal: true

require 'gl_command'

module Scheduling
  module Strategies
    class ContentStrategy < GLCommand::Callable
      requires persona: Persona
      returns :selected_photo

      def call
        result = select_with_content_strategy

        if result[:success]
          handle_photo_found(result)
        else
          handle_no_photo_found(result[:error])
        end
      end

      private

      def select_with_content_strategy
        ::ContentStrategy::SelectNextPost.new(persona: persona).call
      rescue StandardError => e
        { success: false, error: "Strategy selection failed: #{e.message}" }
      end

      def handle_no_photo_found(error_message)
        message = "Content strategy could not select photo for persona: #{persona.name}. #{error_message}"
        Rails.logger.warn(message)
        context.selected_photo = nil
      end

      def handle_photo_found(result)
        photo = result[:photo]
        cluster = result[:cluster]
        optimal_time = result[:optimal_time]
        hashtags = result[:hashtags]

        post = create_posting_record(photo, cluster, optimal_time, hashtags)

        if post.persisted?
          handle_instagram_posting(post, photo, cluster)
          context.selected_photo = photo
        else
          message = "Failed to create posting record for photo #{photo.id}"
          Rails.logger.error(message)
          context.selected_photo = nil
        end
      end

      def create_posting_record(photo, cluster, optimal_time, hashtags)
        caption = generate_caption(photo, hashtags)

        Scheduling::Post.create!(
          photo: photo,
          persona: persona,
          caption: caption,
          cluster: cluster,
          strategy_name: result_strategy_name,
          optimal_time_calculated: optimal_time,
          hashtags: hashtags,
          status: 'posting'
        )
      end

      def generate_caption(photo, hashtags)
        base_caption = photo.photo_analysis&.caption || ""
        hashtag_string = hashtags.join(' ')
        
        if base_caption.present?
          "#{base_caption}\n\n#{hashtag_string}"
        else
          hashtag_string
        end
      end

      def result_strategy_name
        @result_strategy_name ||= 'content_strategy'
      end

      def handle_instagram_posting(post, photo, cluster)
        public_url_result = generate_public_photo_url(photo)

        if public_url_result.success?
          post_to_instagram(post, photo, public_url_result.public_photo_url, cluster)
        else
          mark_post_failed(post, photo, "URL generation failed: #{public_url_result.errors}")
        end
      rescue StandardError => e
        mark_post_failed(post, photo, "Unexpected error: #{e.message}")
      end

      def post_to_instagram(post, photo, public_photo_url, cluster)
        instagram_result = send_to_instagram(post, public_photo_url)

        if instagram_result.success?
          update_post_as_posted(post, instagram_result.instagram_post_id, cluster)
        else
          mark_post_failed(post, photo, "Instagram posting failed: #{instagram_result.errors.join(', ')}")
        end
      end

      def update_post_as_posted(post, provider_post_id, cluster)
        post.update!(
          provider_post_id: provider_post_id,
          posted_at: Time.current
        )
        post.mark_as_posted!

        # Call strategy lifecycle hook
        record_strategy_history(post, cluster)
      end

      def record_strategy_history(post, cluster)
        strategy_instance = get_strategy_instance
        strategy_instance.after_post(
          post: post,
          photo: post.photo,
          cluster: cluster
        )
      rescue StandardError => e
        Rails.logger.error("Failed to record strategy history: #{e.message}")
      end

      def get_strategy_instance
        context_obj = ::ContentStrategy::Context.new(persona: persona)
        strategy_class = ::ContentStrategy::StrategyRegistry.get(active_strategy_name)
        strategy_class.new(context: context_obj)
      end

      def active_strategy_name
        state = ::ContentStrategy::StrategyState.find_by(persona: persona)
        state&.active_strategy&.to_sym || :theme_of_week_strategy
      end

      def mark_post_failed(post, photo, error_message)
        post.mark_as_failed!
        Rails.logger.error("Posting failed for photo #{photo.id}: #{error_message}")
      end

      def generate_public_photo_url(photo)
        Scheduling::Commands::GeneratePublicPhotoUrl.call!(photo: photo)
      end

      def send_to_instagram(post, public_photo_url)
        Scheduling::Commands::SendPostToInstagram.call!(
          public_photo_url: public_photo_url,
          caption: post.caption,
          persona: persona
        )
      end
    end
  end
end
