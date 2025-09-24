# frozen_string_literal: true

require 'gl_command'

module Photos
  class CreatePhotoAnalysis < GLCommand::Callable
    requires :photo, :sharpness_score, :exposure_score, :aesthetic_score, :detected_objects
    returns :photo_analysis

    def call
      validate_photo

      photo_analysis = PhotoAnalysis.create!(
        photo: photo,
        sharpness_score: sharpness_score,
        exposure_score: exposure_score,
        aesthetic_score: aesthetic_score,
        detected_objects: detected_objects
      )

      context.photo_analysis = photo_analysis
    rescue ActiveRecord::RecordInvalid => e
      stop_and_fail!("Failed to create PhotoAnalysis record: #{e.message}")
    rescue StandardError => e
      stop_and_fail!("Unexpected error creating PhotoAnalysis record: #{e.message}")
    end

    private

    def validate_photo
      return if photo.class.name == 'Photo'

      stop_and_fail!("Invalid photo: expected Photo object, got #{photo.class}")
    end
  end
end