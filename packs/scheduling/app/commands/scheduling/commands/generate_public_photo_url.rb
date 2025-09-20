# frozen_string_literal: true

module Scheduling
  module Commands
    class GeneratePublicPhotoUrl < GLCommand::Callable
      requires :photo
      returns :public_photo_url

      def call
        # Generate a public URL for the photo's ActiveStorage attachment
        # This assumes the image is attached via has_one_attached :image
        unless photo.image.attached?
          stop_and_fail!('Photo must have an attached image')
          return
        end

        # Generate a permanent public URL (this may need to be adjusted based on ActiveStorage configuration)
        context.public_photo_url = Rails.application.routes.url_helpers.url_for(photo.image)
      end

      # No rollback needed as this is a read-only operation
    end
  end
end
