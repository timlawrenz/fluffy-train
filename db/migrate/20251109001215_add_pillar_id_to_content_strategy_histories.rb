class AddPillarIdToContentStrategyHistories < ActiveRecord::Migration[8.0]
  def change
    add_reference :content_strategy_histories, :pillar, null: true, foreign_key: { to_table: :content_pillars }, index: true
  end
end
