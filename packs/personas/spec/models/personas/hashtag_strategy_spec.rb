# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Personas::HashtagStrategy do
  describe '#initialize' do
    it 'accepts hash with symbol keys' do
      strategy = described_class.new(
        niche_categories: ['lifestyle'],
        target_hashtags: ['#LifestylePhotography'],
        avoid_hashtags: ['#Spam'],
        size_mix: 'balanced'
      )

      expect(strategy.niche_categories).to eq(['lifestyle'])
      expect(strategy.target_hashtags).to eq(['#LifestylePhotography'])
      expect(strategy.avoid_hashtags).to eq(['#Spam'])
      expect(strategy.size_mix).to eq('balanced')
    end

    it 'accepts hash with string keys' do
      strategy = described_class.new(
        'niche_categories' => ['lifestyle'],
        'target_hashtags' => ['#LifestylePhotography'],
        'size_mix' => 'balanced'
      )

      expect(strategy.niche_categories).to eq(['lifestyle'])
    end

    it 'sets defaults' do
      strategy = described_class.new

      expect(strategy.niche_categories).to eq([])
      expect(strategy.target_hashtags).to eq([])
      expect(strategy.avoid_hashtags).to eq([])
      expect(strategy.size_mix).to eq('balanced')
    end
  end

  describe '#valid?' do
    it 'is valid with correct size_mix' do
      strategy = described_class.new(size_mix: 'balanced')
      expect(strategy).to be_valid
    end

    it 'is invalid with incorrect size_mix' do
      strategy = described_class.new(size_mix: 'invalid_mix')
      expect(strategy).not_to be_valid
    end

    it 'is invalid with malformed target hashtags' do
      strategy = described_class.new(target_hashtags: ['not a hashtag'])
      expect(strategy).not_to be_valid
    end

    it 'is valid with properly formatted hashtags' do
      strategy = described_class.new(
        target_hashtags: ['#ValidTag', '#AnotherTag'],
        avoid_hashtags: ['#SpamTag']
      )
      expect(strategy).to be_valid
    end
  end

  describe '#to_hash' do
    it 'converts strategy to hash' do
      strategy = described_class.new(
        niche_categories: ['lifestyle'],
        target_hashtags: ['#LifestylePhotography'],
        size_mix: 'balanced'
      )

      hash = strategy.to_hash

      expect(hash).to include(
        niche_categories: ['lifestyle'],
        target_hashtags: ['#LifestylePhotography'],
        size_mix: 'balanced'
      )
    end
  end

  describe '.from_hash' do
    it 'creates strategy from hash' do
      hash = {
        niche_categories: ['lifestyle'],
        target_hashtags: ['#LifestylePhotography'],
        size_mix: 'niche_heavy'
      }

      strategy = described_class.from_hash(hash)

      expect(strategy.niche_categories).to eq(['lifestyle'])
      expect(strategy.size_mix).to eq('niche_heavy')
    end

    it 'returns nil for empty hash' do
      expect(described_class.from_hash({})).to be_nil
    end

    it 'returns nil for nil' do
      expect(described_class.from_hash(nil)).to be_nil
    end
  end

  describe '#size_distribution' do
    it 'returns balanced distribution for balanced mix' do
      strategy = described_class.new(size_mix: 'balanced')
      dist = strategy.size_distribution

      expect(dist[:large]).to eq(2..3)
      expect(dist[:medium]).to eq(3..4)
      expect(dist[:niche]).to eq(3..5)
    end

    it 'returns niche-heavy distribution for niche_heavy mix' do
      strategy = described_class.new(size_mix: 'niche_heavy')
      dist = strategy.size_distribution

      expect(dist[:large]).to eq(1..2)
      expect(dist[:niche]).to eq(5..7)
    end

    it 'returns broad reach distribution for broad_reach mix' do
      strategy = described_class.new(size_mix: 'broad_reach')
      dist = strategy.size_distribution

      expect(dist[:large]).to eq(3..4)
      expect(dist[:niche]).to eq(2..3)
    end
  end
end
