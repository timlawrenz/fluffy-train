module ContentStrategy
  class StrategyState < ApplicationRecord
    self.table_name = "content_strategy_states"

    belongs_to :persona

    validates :persona_id, presence: true, uniqueness: true

    def get_state(key)
      state_data[key.to_s]
    end

    def set_state(key, value)
      self.state_data ||= {}
      self.state_data[key.to_s] = value
      save!
    end

    def update_state(key, updates)
      self.state_data ||= {}
      current_value = self.state_data[key.to_s] || {}
      self.state_data[key.to_s] = current_value.merge(updates.stringify_keys)
      save!
    end

    def reset_state!
      update!(state_data: {}, started_at: nil)
    end
  end
end
