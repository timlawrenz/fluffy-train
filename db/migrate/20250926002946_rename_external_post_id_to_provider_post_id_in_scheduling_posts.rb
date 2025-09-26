# frozen_string_literal: true

class RenameExternalPostIdToProviderPostIdInSchedulingPosts < ActiveRecord::Migration[8.0]
  def change
    rename_column :scheduling_posts, :external_post_id, :provider_post_id
  end
end
