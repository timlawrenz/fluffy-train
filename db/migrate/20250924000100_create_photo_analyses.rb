# frozen_string_literal: true

class CreatePhotoAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :photo_analyses do |t|
      t.references :photo, null: false, foreign_key: true
      t.float :sharpness_score
      t.float :exposure_score
      t.float :aesthetic_score
      t.jsonb :detected_objects

      t.timestamps
    end
  end
end
