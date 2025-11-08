# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Personas::CaptionConfig do
  describe '#initialize' do
    it 'accepts hash with symbol keys' do
      config = described_class.new(
        tone: 'casual',
        voice_attributes: ['witty', 'authentic'],
        style: { use_emoji: true, avg_length: 'medium' }
      )

      expect(config.tone).to eq('casual')
      expect(config.voice_attributes).to eq(['witty', 'authentic'])
      expect(config.style[:use_emoji]).to be true
    end

    it 'accepts hash with string keys' do
      config = described_class.new(
        'tone' => 'professional',
        'voice_attributes' => ['formal'],
        'style' => { 'avg_length' => 'long' }
      )

      expect(config.tone).to eq('professional')
      expect(config.voice_attributes).to eq(['formal'])
    end

    it 'sets defaults' do
      config = described_class.new

      expect(config.tone).to eq('casual')
      expect(config.voice_attributes).to eq([])
      expect(config.style[:avg_length]).to eq('medium')
    end
  end

  describe '#valid?' do
    it 'is valid with correct tone' do
      config = described_class.new(tone: 'casual')
      expect(config).to be_valid
    end

    it 'is invalid with incorrect tone' do
      config = described_class.new(tone: 'invalid_tone')
      expect(config).not_to be_valid
      expect(config.errors.first).to include('tone must be one of')
    end

    it 'is invalid with incorrect avg_length' do
      config = described_class.new(
        tone: 'casual',
        style: { avg_length: 'invalid' }
      )
      expect(config).not_to be_valid
      expect(config.errors.first).to include('avg_length must be one of')
    end

    it 'is invalid with incorrect emoji_density' do
      config = described_class.new(
        tone: 'casual',
        style: { emoji_density: 'invalid' }
      )
      expect(config).not_to be_valid
      expect(config.errors.first).to include('emoji_density must be one of')
    end
  end

  describe '#to_hash' do
    it 'converts config to hash' do
      config = described_class.new(
        tone: 'casual',
        voice_attributes: ['witty'],
        topics: ['lifestyle']
      )

      hash = config.to_hash

      expect(hash[:tone]).to eq('casual')
      expect(hash[:voice_attributes]).to eq(['witty'])
      expect(hash[:topics]).to eq(['lifestyle'])
    end
  end

  describe '.from_hash' do
    it 'creates config from hash' do
      hash = {
        tone: 'playful',
        voice_attributes: ['fun', 'energetic'],
        style: { use_emoji: true }
      }

      config = described_class.from_hash(hash)

      expect(config.tone).to eq('playful')
      expect(config.voice_attributes).to eq(['fun', 'energetic'])
      expect(config.style[:use_emoji]).to be true
    end

    it 'returns nil for empty hash' do
      expect(described_class.from_hash({})).to be_nil
    end

    it 'returns nil for nil' do
      expect(described_class.from_hash(nil)).to be_nil
    end
  end
end
