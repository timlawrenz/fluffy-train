# frozen_string_literal: true

require 'gl_command'
require_relative '../../../clients/ollama_client'

module Photos
  module Analyse
    class Caption < GLCommand::Callable
      requires photo: Photo
      allows :llm_client
      returns :caption

      def call
        validate_photo_file

        caption = client.generate_caption(file_path: photo.path)

        save_caption_to_analysis(caption)
        context.caption = caption
      rescue OllamaClient::Error => e
        stop_and_fail!("Failed to generate caption for image: #{e.message}")
      rescue StandardError => e
        stop_and_fail!("Unexpected error during caption generation: #{e.message}")
      end

      private

      def client
        context.llm_client || OllamaClient
      end

      def validate_photo_file
        return if File.exist?(photo.path)

        stop_and_fail!("Photo file not found at path: #{photo.path}")
      end

      def save_caption_to_analysis(caption)
        # Create photo_analysis if it doesn't exist, or update if it does
        photo_analysis = photo.photo_analysis || photo.build_photo_analysis
        photo_analysis.caption = caption
        photo_analysis.save!
      end
    end
  end
end
