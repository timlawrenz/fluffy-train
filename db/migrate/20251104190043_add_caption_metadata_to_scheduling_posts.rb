class AddCaptionMetadataToSchedulingPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :scheduling_posts, :caption_metadata, :jsonb
  end
end
