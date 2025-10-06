# frozen_string_literal: true

class AddClusterToPhotos < ActiveRecord::Migration[8.0]
  def change
    add_reference :photos, :cluster, null: true, foreign_key: true
  end
end
