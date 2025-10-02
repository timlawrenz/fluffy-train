# frozen_string_literal: true

require 'gl_command'
require_relative '../../../clients/ollama_client'

module Photos
  module Analyse
    class Aesthetics < GLCommand::Callable
      requires photo: Photo
      allows :llm_client
      returns :aesthetic_score

      def call
        validate_photo_file

        score = client.get_aesthetic_score(file_path: photo.path)

        context.aesthetic_score = score
      rescue OllamaClient::Error => e
        stop_and_fail!("Failed to get aesthetic score for image: #{e.message}")
      rescue StandardError => e
        stop_and_fail!("Unexpected error during aesthetic analysis: #{e.message}")
      end

      private

      def client
        context.llm_client || OllamaClient
      end

      def validate_photo_file
        return if File.exist?(photo.path)

        stop_and_fail!("Photo file not found at path: #{photo.path}")
      end
    end
  end
end
