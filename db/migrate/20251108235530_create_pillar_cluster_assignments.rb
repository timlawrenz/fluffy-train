class CreatePillarClusterAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :pillar_cluster_assignments do |t|
      t.references :pillar, null: false, foreign_key: { to_table: :content_pillars, on_delete: :cascade }
      t.references :cluster, null: false, foreign_key: { to_table: :clusters, on_delete: :cascade }
      t.boolean :primary, default: false, null: false
      t.text :notes

      t.timestamps
    end

    add_index :pillar_cluster_assignments, [:pillar_id, :cluster_id], unique: true, name: 'index_pillar_cluster_unique'
  end
end
