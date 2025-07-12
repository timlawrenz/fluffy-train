# frozen_string_literal: true

class CreatePersonas < ActiveRecord::Migration[8.0]
  def change
    create_table :personas do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :personas, :name, unique: true
  end
end
