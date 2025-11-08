class AddHashtagStrategyToPersonas < ActiveRecord::Migration[8.0]
  def change
    add_column :personas, :hashtag_strategy, :jsonb, default: {}
  end
end
