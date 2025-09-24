# frozen_string_literal: true

require 'vips'

module Photos
  module Analyse
    class Exposure < GLCommand::Callable
      requires :photo
      returns :exposure_score

      def call
        validate_photo_file

        image = load_image
        score = calculate_mean_brightness(image)

        context.exposure_score = score.to_f
      rescue Vips::Error => e
        stop_and_fail!("Failed to analyze image exposure: #{e.message}")
      rescue StandardError => e
        stop_and_fail!("Unexpected error during exposure analysis: #{e.message}")
      end

      private

      def validate_photo_file
        return if File.exist?(photo.path)

        stop_and_fail!("Photo file not found at path: #{photo.path}")
      end

      def load_image
        Vips::Image.new_from_file(photo.path)
      end

      def calculate_mean_brightness(image)
        # Convert to grayscale if needed to get luminance values
        image = image.colourspace(:grey) if image.bands > 1

        # Calculate the mean brightness (average pixel value)
        # This gives us a value between 0 (black) and 255 (white) for 8-bit images
        mean_brightness = image.avg

        # Normalize to 0.0-1.0 range for consistency
        # Most images are 8-bit (0-255 range), but handle different bit depths
        max_value = image.format == :uchar ? 255.0 : ((2**image.format.to_s.scan(/\d+/).first.to_i) - 1).to_f
        mean_brightness / max_value
      end
    end
  end
end
