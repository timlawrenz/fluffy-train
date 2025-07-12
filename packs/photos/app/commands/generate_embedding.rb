# frozen_string_literal: true

class GenerateEmbedding < GLCommand::Callable
  requires photo: Photo
  returns :photo

  def call
    unless File.exist?(photo.path)
      stop_and_fail!("Photo file not found at path: #{photo.path}", no_notify: true)
      return
    end

    if photo.embedding.present?
      context.photo = photo
      return
    end

    embedding = ImageEmbedClient.generate_embedding(file_path: photo.path)
    if photo.update(embedding: embedding)
      context.photo = photo
    else
      stop_and_fail!(photo.errors.full_messages.to_sentence, no_notify: true)
    end
  rescue ImageEmbedClient::Error => e
    stop_and_fail!("Failed to generate embedding: #{e.message}")
  end
end
