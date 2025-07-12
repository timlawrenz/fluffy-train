# frozen_string_literal: true

class CreatePhotos < ActiveRecord::Migration[8.0]
  def change
    create_table :photos do |t|
      t.references :persona, null: false, foreign_key: true
      t.string :path, null: false

      t.timestamps
    end
  end
end
