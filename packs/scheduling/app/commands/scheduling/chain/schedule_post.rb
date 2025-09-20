# frozen_string_literal: true

module Scheduling
  module Chain
    class SchedulePost < GLCommand::Chainable
      requires :photo, :persona, :caption
      returns :post

      chain(
        Scheduling::Commands::CreatePostRecord,
        Scheduling::Commands::GeneratePublicPhotoUrl,
        Scheduling::Commands::SendPostToBuffer,
        Scheduling::Commands::UpdatePostWithBufferId
      )

      def call
        validate_arguments!
        execute_chain
      end

      private

      def validate_arguments!
        stop_and_fail!('photo must be a Photo instance') unless photo.is_a?(Photo)
        stop_and_fail!('persona must be a Persona instance') unless persona.is_a?(Persona)
        return if caption.is_a?(String) && caption.present?

        stop_and_fail!('caption must be a non-empty string')
      end

      def execute_chain
        chain(
          photo: photo,
          persona: persona,
          caption: caption
        )
      end
    end
  end
end
