# frozen_string_literal: true

class RenameBufferColumns < ActiveRecord::Migration[7.1]
  def change
    # Rename the buffer_post_id on scheduling_posts to be more generic
    rename_column :scheduling_posts, :buffer_post_id, :external_post_id

    # Remove the now-unused buffer_profile_id from personas
    remove_column :personas, :buffer_profile_id, :string
  end
end