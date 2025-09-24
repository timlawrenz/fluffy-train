# frozen_string_literal: true

require 'vips'

module Photos
  module Analyse
    class Sharpness < GLCommand::Callable
      requires :photo
      returns :sharpness_score

      def call
        validate_photo_file

        image = load_image
        score = calculate_laplacian_variance(image)

        context.sharpness_score = score.to_f
      rescue Vips::Error => e
        stop_and_fail!("Failed to analyze image sharpness: #{e.message}")
      rescue StandardError => e
        stop_and_fail!("Unexpected error during sharpness analysis: #{e.message}")
      end

      private

      def validate_photo_file
        return if File.exist?(photo.path)

        stop_and_fail!("Photo file not found at path: #{photo.path}")
      end

      def load_image
        Vips::Image.new_from_file(photo.path)
      end

      def calculate_laplacian_variance(image)
        # Convert to grayscale if needed
        image = image.colourspace(:grey) if image.bands > 1

        # Apply Laplacian convolution and calculate variance
        laplacian_image = image.conv(laplacian_kernel)

        # Calculate the variance of the Laplacian
        mean = laplacian_image.avg
        squared_diff = (laplacian_image - mean)**2
        squared_diff.avg
      end

      def laplacian_kernel
        # Standard Laplacian kernel: [[0, -1, 0], [-1, 4, -1], [0, -1, 0]]
        Vips::Image.new_from_array([
                                     [0, -1, 0],
                                     [-1, 4, -1],
                                     [0, -1, 0]
                                   ])
      end
    end
  end
end
