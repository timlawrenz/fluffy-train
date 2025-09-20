# frozen_string_literal: true

module Scheduling
  module Commands
    class SendPostToBuffer < GLCommand::Callable
      requires :public_photo_url, :caption, :persona
      returns :buffer_post_id

      def call
        validate_persona!
        send_to_buffer!
      end

      private

      def validate_persona!
        return if persona.respond_to?(:buffer_profile_id) && persona.buffer_profile_id.present?

        stop_and_fail!('Persona must have a buffer_profile_id')
      end

      def send_to_buffer!
        response = create_buffer_post
        extract_buffer_post_id(response)
      rescue Buffer::Client::Error => e
        stop_and_fail!("Failed to send post to Buffer: #{e.message}")
      end

      def create_buffer_post
        buffer_client = Buffer::Client.new
        buffer_client.create_post(
          image_url: public_photo_url,
          caption: caption,
          buffer_profile_id: persona.buffer_profile_id
        )
      end

      def extract_buffer_post_id(response)
        context.buffer_post_id = response['id'] || response[:id]
        stop_and_fail!('Buffer API did not return a post ID') if context.buffer_post_id.blank?
      end

      def rollback
        return if context.buffer_post_id.blank?

        begin
          buffer_client = Buffer::Client.new
          buffer_client.destroy_post(buffer_post_id: context.buffer_post_id)
        rescue Buffer::Client::Error => e
          # Log the error but don't fail the rollback
          Rails.logger.error("Failed to rollback Buffer post #{context.buffer_post_id}: #{e.message}")
        end
      end
    end
  end
end
