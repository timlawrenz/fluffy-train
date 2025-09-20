# frozen_string_literal: true

class AddBufferProfileIdToPersonas < ActiveRecord::Migration[8.0]
  def change
    add_column :personas, :buffer_profile_id, :string
  end
end
