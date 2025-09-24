# frozen_string_literal: true

require 'gl_command'
require_relative '../../../clients/ollama_client'

module Photos
  module Analyse
    class Aesthetics < GLCommand::Callable
      requires :photo
      returns :aesthetic_score

      def call
        validate_photo_file

        score = OllamaClient.analyze_aesthetics(file_path: photo.path)
        validate_aesthetic_score(score)

        context.aesthetic_score = score.to_f
      rescue OllamaClient::Error => e
        stop_and_fail!("Failed to analyze image aesthetics: #{e.message}")
      rescue StandardError => e
        stop_and_fail!("Unexpected error during aesthetic analysis: #{e.message}")
      end

      private

      def validate_photo_file
        return if File.exist?(photo.path)

        stop_and_fail!("Photo file not found at path: #{photo.path}")
      end

      def validate_aesthetic_score(score)
        return if score.is_a?(Numeric) && score >= 1.0 && score <= 10.0

        stop_and_fail!("Invalid aesthetic score: must be a number between 1.0 and 10.0, got #{score}")
      end
    end
  end
end
