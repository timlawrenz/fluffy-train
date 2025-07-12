# frozen_string_literal: true

class AddUniqueIndexToPhotosPath < ActiveRecord::Migration[8.0]
  def change
    add_index :photos, :path, unique: true
  end
end
