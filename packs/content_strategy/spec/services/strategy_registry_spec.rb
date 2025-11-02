require 'rails_helper'

RSpec.describe ContentStrategy::StrategyRegistry do
  before(:each) do
    described_class.instance_variable_set(:@strategies, nil)
  end

  describe '.register' do
    it 'registers a strategy class' do
      strategy_class = Class.new
      described_class.register(:test_strategy, strategy_class)
      
      expect(described_class.all).to include(:test_strategy)
    end
  end

  describe '.get' do
    let(:strategy_class) { Class.new }

    before do
      described_class.register(:registered_strategy, strategy_class)
    end

    it 'returns registered strategy class' do
      expect(described_class.get(:registered_strategy)).to eq(strategy_class)
    end

    it 'raises UnknownStrategyError for unregistered strategy' do
      expect {
        described_class.get(:unknown_strategy)
      }.to raise_error(ContentStrategy::UnknownStrategyError)
    end
  end

  describe '.exists?' do
    before do
      described_class.register(:exists_test, Class.new)
    end

    it 'returns true for registered strategy' do
      expect(described_class.exists?(:exists_test)).to be true
    end

    it 'returns false for unregistered strategy' do
      expect(described_class.exists?(:not_registered)).to be false
    end
  end

  describe '.all' do
    it 'returns array of registered strategy names' do
      described_class.register(:strategy_one, Class.new)
      described_class.register(:strategy_two, Class.new)
      
      expect(described_class.all).to match_array([:strategy_one, :strategy_two])
    end
  end
end
