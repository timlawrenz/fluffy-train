require 'rails_helper'

RSpec.describe ContentStrategy::StrategyConfig do
  describe '.default' do
    it 'returns a config with default values' do
      config = described_class.default
      
      expect(config.posting_frequency_min).to eq(3)
      expect(config.posting_frequency_max).to eq(5)
      expect(config.optimal_time_start_hour).to eq(5)
      expect(config.optimal_time_end_hour).to eq(8)
      expect(config.variety_min_days_gap).to eq(2)
      expect(config.hashtag_count_min).to eq(5)
      expect(config.hashtag_count_max).to eq(12)
    end
  end

  describe '.from_yaml' do
    it 'creates config from hash' do
      config = described_class.from_yaml(
        posting_frequency_min: 2,
        posting_frequency_max: 4,
        timezone: 'America/New_York'
      )
      
      expect(config.posting_frequency_min).to eq(2)
      expect(config.posting_frequency_max).to eq(4)
      expect(config.timezone).to eq('America/New_York')
    end
  end

  describe 'validations' do
    it 'validates posting frequency is positive' do
      config = described_class.new(posting_frequency_min: 0)
      expect(config).not_to be_valid
    end

    it 'validates posting frequency is within range' do
      config = described_class.new(posting_frequency_min: 10)
      expect(config).not_to be_valid
    end

    it 'validates time hours are within 24-hour range' do
      config = described_class.new(optimal_time_start_hour: 25)
      expect(config).not_to be_valid
    end
  end
end
