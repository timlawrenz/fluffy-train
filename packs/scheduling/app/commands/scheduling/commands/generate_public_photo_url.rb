# frozen_string_literal: true

module Scheduling
  module Commands
    class GeneratePublicPhotoUrl < GLCommand::Callable
      requires photo: Photo
      returns public_photo_url: String

      def call
        # Generate a public URL for the photo's ActiveStorage attachment
        # This assumes the image is attached via has_one_attached :image
        unless photo.image.attached?
          stop_and_fail!('Photo must have an attached image')
          return
        end

        # Generate a permanent public URL. As the storage is configured with `public: true`,
        # this will return the direct URL to the file on the S3-compatible service.
        context.public_photo_url = photo.image.url
      end

      # No rollback needed as this is a read-only operation
    end
  end
end
