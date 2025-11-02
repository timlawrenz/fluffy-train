class CreateContentStrategyState < ActiveRecord::Migration[8.0]
  def change
    create_table :content_strategy_states do |t|
      t.bigint :persona_id, null: false
      t.string :active_strategy
      t.jsonb :strategy_config, default: {}
      t.jsonb :state_data, default: {}
      t.datetime :started_at

      t.timestamps
    end
    add_index :content_strategy_states, :persona_id, unique: true
    add_foreign_key :content_strategy_states, :personas
  end
end
