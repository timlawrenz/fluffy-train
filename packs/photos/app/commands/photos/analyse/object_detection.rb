# frozen_string_literal: true

require 'gl_command'
require_relative '../../../clients/ollama_client'

module Photos
  module Analyse
    class ObjectDetection < GLCommand::Callable
      requires :photo
      returns :detected_objects

      def call
        validate_photo_file

        objects = OllamaClient.detect_objects(file_path: photo.path)
        validate_objects_response(objects)

        context.detected_objects = objects
      rescue OllamaClient::Error => e
        stop_and_fail!("Failed to detect objects in image: #{e.message}")
      rescue StandardError => e
        stop_and_fail!("Unexpected error during object detection: #{e.message}")
      end

      private

      def validate_photo_file
        return if File.exist?(photo.path)

        stop_and_fail!("Photo file not found at path: #{photo.path}")
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def validate_objects_response(objects)
        stop_and_fail!("Invalid response format: expected array but got #{objects.class}") unless objects.is_a?(Array)

        objects.each_with_index do |obj, index|
          stop_and_fail!("Invalid object at index #{index}: expected hash but got #{obj.class}") unless obj.is_a?(Hash)

          unless obj.key?('label') && obj.key?('confidence')
            stop_and_fail!("Invalid object at index #{index}: missing required keys 'label' or 'confidence'")
          end

          unless obj['confidence'].is_a?(Numeric) && obj['confidence'] >= 0.0 && obj['confidence'] <= 1.0
            stop_and_fail!("Invalid confidence value at index #{index}: must be a number between 0.0 and 1.0")
          end

          unless obj['label'].is_a?(String) && !obj['label'].strip.empty?
            stop_and_fail!("Invalid label at index #{index}: must be a non-empty string")
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    end
  end
end
