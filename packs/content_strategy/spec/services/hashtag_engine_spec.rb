require 'rails_helper'

RSpec.describe ContentStrategy::HashtagEngine do
  let(:photo) { instance_double(Photo, photo_analysis: nil) }
  let(:cluster) { instance_double(Clustering::Cluster, name: 'Mountain Landscapes') }

  describe '.generate' do
    it 'generates hashtags from cluster name' do
      hashtags = described_class.generate(photo: photo, cluster: cluster, count: 8)
      
      expect(hashtags).to be_an(Array)
      expect(hashtags.size).to be <= 8
      expect(hashtags).to all(start_with('#'))
    end

    it 'includes cluster-based tags' do
      hashtags = described_class.generate(photo: photo, cluster: cluster, count: 10)
      
      expect(hashtags.any? { |tag| tag.include?('mountain') || tag.include?('landscape') }).to be true
    end

    it 'formats hashtags properly' do
      hashtags = described_class.generate(photo: photo, cluster: cluster, count: 5)
      
      hashtags.each do |tag|
        expect(tag).to match(/^#[a-z0-9]+$/)
      end
    end

    it 'returns unique hashtags' do
      hashtags = described_class.generate(photo: photo, cluster: cluster, count: 10)
      
      expect(hashtags.uniq.size).to eq(hashtags.size)
    end
  end

  describe '#detect_category' do
    it 'detects landscape category from cluster name' do
      engine = described_class.new(photo: photo, cluster: cluster, count: 5)
      category = engine.send(:detect_category)
      
      expect(category).to eq(:landscape)
    end

    it 'detects portrait category' do
      portrait_cluster = instance_double(Clustering::Cluster, name: 'Portrait Photography')
      engine = described_class.new(photo: photo, cluster: portrait_cluster, count: 5)
      
      expect(engine.send(:detect_category)).to eq(:portrait)
    end
  end
end
