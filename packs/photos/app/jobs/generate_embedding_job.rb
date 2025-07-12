# frozen_string_literal: true

class GenerateEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(photo_id)
    photo = Photo.find_by(id: photo_id)
    return unless photo

    Photos.generate_embedding(photo: photo)
  end
end
