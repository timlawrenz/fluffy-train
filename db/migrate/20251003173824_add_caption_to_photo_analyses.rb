# frozen_string_literal: true

class AddCaptionToPhotoAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_column :photo_analyses, :caption, :text
  end
end
