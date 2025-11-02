class CreateContentStrategyHistory < ActiveRecord::Migration[8.0]
  def change
    create_table :content_strategy_histories do |t|
      t.bigint :persona_id, null: false
      t.bigint :post_id, null: false
      t.bigint :cluster_id
      t.string :strategy_name
      t.jsonb :decision_context, default: {}

      t.timestamps
    end
    add_index :content_strategy_histories, :persona_id
    add_index :content_strategy_histories, :cluster_id
    add_index :content_strategy_histories, [:persona_id, :created_at]
    add_foreign_key :content_strategy_histories, :personas
    add_foreign_key :content_strategy_histories, :scheduling_posts, column: :post_id
    add_foreign_key :content_strategy_histories, :clusters
  end
end
