# frozen_string_literal: true

class CreateClusters < ActiveRecord::Migration[8.0]
  def change
    create_table :clusters do |t|
      t.string :name
      t.integer :status, default: 0
      t.integer :photos_count, default: 0

      t.timestamps
    end
  end
end
