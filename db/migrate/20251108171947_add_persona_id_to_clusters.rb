# frozen_string_literal: true

class AddPersonaIdToClusters < ActiveRecord::Migration[8.0]
  def change
    add_reference :clusters, :persona, foreign_key: true, index: true
    
    # Backfill: Assign persona_id based on photos in cluster
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE clusters
          SET persona_id = (
            SELECT photos.persona_id
            FROM photos
            WHERE photos.cluster_id = clusters.id
            GROUP BY photos.persona_id
            ORDER BY COUNT(*) DESC
            LIMIT 1
          )
          WHERE EXISTS (
            SELECT 1 FROM photos WHERE photos.cluster_id = clusters.id
          )
        SQL
        
        # Delete orphaned clusters (clusters with no photos)
        execute <<-SQL
          DELETE FROM clusters
          WHERE persona_id IS NULL
        SQL
      end
    end
    
    # Add NOT NULL constraint after backfill
    change_column_null :clusters, :persona_id, false
  end
end
