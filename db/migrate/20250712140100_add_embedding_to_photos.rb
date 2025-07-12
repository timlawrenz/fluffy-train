# frozen_string_literal: true

class AddEmbeddingToPhotos < ActiveRecord::Migration[8.0]
  def change
    add_column :photos, :embedding, :vector, limit: 512
  end
end
