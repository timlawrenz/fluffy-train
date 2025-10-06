# frozen_string_literal: true

require 'gl_command'

module Photos
  module Analyse
    class SaveResults < GLCommand::Callable
      requires :photo, :sharpness_score, :exposure_score, :aesthetic_score, :detected_objects
      returns :photo_analysis

      def call
        validate_inputs
        create_photo_analysis
      rescue ActiveRecord::RecordInvalid => e
        stop_and_fail!("Failed to save photo analysis: #{e.message}")
      rescue StandardError => e
        context.errors.add(:base, e.message)
        context.fail!
      end

      private

      def create_photo_analysis
        # Use existing photo_analysis if it exists (e.g., from Caption command), otherwise create new
        photo_analysis = photo.photo_analysis || PhotoAnalysis.new(photo: photo)

        photo_analysis.assign_attributes(
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )

        photo_analysis.save!
        context.photo_analysis = photo_analysis
      end

      def rollback
        # If a PhotoAnalysis was created but a later command failed,
        # we should clean it up
        return unless context.photo_analysis

        context.photo_analysis.destroy
      rescue StandardError => e
        # Log the rollback failure but don't re-raise to avoid masking the original error
        Rails.logger.error("Failed to rollback PhotoAnalysis creation: #{e.message}")
      end

      def validate_inputs
        stop_and_fail!('Photo is required') unless photo
        stop_and_fail!('Sharpness score must be numeric') unless sharpness_score.is_a?(Numeric)
        stop_and_fail!('Exposure score must be numeric') unless exposure_score.is_a?(Numeric)
        stop_and_fail!('Aesthetic score must be numeric') unless aesthetic_score.is_a?(Numeric)
        stop_and_fail!('Detected objects must be an array') unless detected_objects.is_a?(Array)
      end
    end
  end
end
