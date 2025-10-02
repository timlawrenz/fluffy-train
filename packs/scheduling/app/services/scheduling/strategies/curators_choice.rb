# frozen_string_literal: true

require 'gl_command'

module Scheduling
  module Strategies
    class CuratorsChoice < GLCommand::Callable
      requires persona: Persona
      returns :selected_photo

      def call
        photo = find_highest_rated_unposted_photo

        if photo.nil?
          message = "No unposted photos found for curator's choice strategy for persona: #{persona.name}"
          Rails.logger.warn(message)
          context.selected_photo = nil
        else
          context.selected_photo = photo
        end
      end

      private

      def find_highest_rated_unposted_photo
        # Find photos for this persona that don't have an associated Scheduling::Post
        # Join with photo_analyses and order by aesthetic_score descending
        persona.photos
               .joins(:photo_analysis)
               .where.not(id: posted_photo_ids_for_persona)
               .order('photo_analyses.aesthetic_score DESC NULLS LAST')
               .first
      end

      def posted_photo_ids_for_persona
        Scheduling::Post.where(persona: persona).pluck(:photo_id)
      end
    end
  end
end
