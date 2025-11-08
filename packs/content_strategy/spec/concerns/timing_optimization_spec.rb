require 'rails_helper'

RSpec.describe ContentStrategy::Concerns::TimingOptimization do
  let(:test_class) do
    Class.new do
      include ContentStrategy::Concerns::TimingOptimization
    end
  end
  
  let(:instance) { test_class.new }
  let(:config) { ContentStrategy::ConfigLoader.load }
  let(:persona) { FactoryBot.create(:persona) }
  let(:context) { ContentStrategy::Context.new(persona: persona, config: config) }

  describe '#calculate_optimal_posting_time' do
    context 'during optimal window' do
      it 'returns current time if in optimal window' do
        time = Time.zone.parse('2025-01-01 06:00:00') # 6am - in optimal window
        
        result = instance.calculate_optimal_posting_time(context: context, preferred_time: time)
        
        expect(result.hour).to eq(6)
      end
    end

    context 'during alternative window' do
      it 'returns current time if in alternative window' do
        time = Time.zone.parse('2025-01-01 11:00:00') # 11am - in alternative window
        
        result = instance.calculate_optimal_posting_time(context: context, preferred_time: time)
        
        expect(result.hour).to eq(11)
      end
    end

    context 'outside posting windows' do
      it 'returns next day optimal time' do
        time = Time.zone.parse('2025-01-01 22:00:00') # 10pm - outside windows
        
        result = instance.calculate_optimal_posting_time(context: context, preferred_time: time)
        
        expect(result.day).to eq(2) # Next day
        expect(result.hour).to be >= config.optimal_time_start_hour
        expect(result.hour).to be < config.optimal_time_end_hour
      end
    end

    context 'with no preferred time' do
      it 'uses current time from context' do
        result = instance.calculate_optimal_posting_time(context: context)
        
        expect(result).to be_a(ActiveSupport::TimeWithZone)
      end
    end

    context 'timezone handling' do
      it 'converts to configured timezone' do
        result = instance.calculate_optimal_posting_time(context: context)
        
        expect(result.zone).to eq(config.timezone)
      end
    end
  end

  describe '#in_optimal_window?' do
    it 'returns true for hours in optimal window' do
      hour = 6 # Within 5-8am window
      
      expect(instance.send(:in_optimal_window?, hour, config)).to be true
    end

    it 'returns false for hours outside optimal window' do
      hour = 10
      
      expect(instance.send(:in_optimal_window?, hour, config)).to be false
    end
  end

  describe '#in_alternative_window?' do
    it 'returns true for hours in alternative window' do
      hour = 12 # Within 10am-3pm window
      
      expect(instance.send(:in_alternative_window?, hour, config)).to be true
    end

    it 'returns false for hours outside alternative window' do
      hour = 20
      
      expect(instance.send(:in_alternative_window?, hour, config)).to be false
    end
  end

  describe '#next_optimal_time' do
    it 'returns tomorrow at optimal start hour' do
      time = Time.zone.parse('2025-01-01 22:00:00')
      
      result = instance.send(:next_optimal_time, time, config)
      
      expect(result.day).to eq(2)
      expect(result.hour).to eq(config.optimal_time_start_hour)
    end

    it 'includes random minutes' do
      time = Time.zone.now
      
      result = instance.send(:next_optimal_time, time, config)
      
      expect(result.min).to be >= 0
      expect(result.min).to be < 60
    end
  end
end
