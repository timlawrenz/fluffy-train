require 'rails_helper'

RSpec.describe ContentStrategy::BaseStrategy do
  let(:persona) { FactoryBot.create(:persona) }
  let(:config) { ContentStrategy::ConfigLoader.load }
  let(:context) { ContentStrategy::Context.new(persona: persona, config: config) }
  
  # Create a concrete strategy for testing
  let(:test_strategy_class) do
    Class.new(described_class) do
      def self.name
        'TestStrategy'
      end

      def select_next_photo
        {
          photo: Photo.first,
          cluster: Clustering::Cluster.first,
          optimal_time: Time.current,
          hashtags: ['#test'],
          format: :static
        }
      end
    end
  end
  
  let(:strategy) { test_strategy_class.new(context: context) }

  describe '#initialize' do
    it 'sets context' do
      expect(strategy.context).to eq(context)
    end
  end

  describe '#select_next_photo' do
    it 'raises NotImplementedError for base class' do
      base_strategy = described_class.new(context: context)
      
      expect {
        base_strategy.select_next_photo
      }.to raise_error(NotImplementedError, /must implement select_next_photo/)
    end
  end

  describe '#get_optimal_posting_time' do
    let(:photo) { FactoryBot.create(:photo) }

    it 'calculates optimal time' do
      time = strategy.get_optimal_posting_time(photo: photo)
      
      expect(time).to be_a(ActiveSupport::TimeWithZone)
    end

    it 'respects timezone configuration' do
      time = strategy.get_optimal_posting_time(photo: photo)
      
      expect(time.zone).to eq(config.timezone)
    end
  end

  describe '#select_hashtags' do
    let(:photo) { FactoryBot.create(:photo) }
    let(:cluster) { FactoryBot.create(:cluster, name: 'Test Cluster') }

    it 'generates hashtags' do
      hashtags = strategy.select_hashtags(photo: photo, cluster: cluster)
      
      expect(hashtags).to be_an(Array)
      expect(hashtags).to all(start_with('#'))
    end

    it 'respects count configuration' do
      hashtags = strategy.select_hashtags(photo: photo, cluster: cluster)
      count = hashtags.size
      
      expect(count).to be >= config.hashtag_count_min
      expect(count).to be <= config.hashtag_count_max
    end
  end

  describe '#validate_posting_frequency' do
    context 'below max posts' do
      it 'allows posting' do
        result = strategy.validate_posting_frequency
        
        expect(result[:allowed]).to be true
      end
    end

    context 'at max posts' do
      before do
        config.posting_frequency_max.times do
          post = FactoryBot.create(:scheduling_post, persona: persona)
          ContentStrategy::HistoryRecord.create!(
            persona: persona,
            post: post,
            strategy_name: 'test'
          )
        end
      end

      it 'disallows posting' do
        result = strategy.validate_posting_frequency
        
        expect(result[:allowed]).to be false
        expect(result[:reason]).to include('Max weekly posts reached')
      end
    end
  end

  describe '#after_post' do
    let(:photo) { FactoryBot.create(:photo) }
    let(:cluster) { FactoryBot.create(:cluster) }
    let(:post) { FactoryBot.create(:scheduling_post, persona: persona, photo: photo) }

    it 'records history' do
      expect {
        strategy.after_post(post: post, photo: photo, cluster: cluster)
      }.to change { ContentStrategy::HistoryRecord.count }.by(1)
    end

    it 'records correct details' do
      strategy.after_post(post: post, photo: photo, cluster: cluster)
      
      history = ContentStrategy::HistoryRecord.last
      expect(history.persona_id).to eq(persona.id)
      expect(history.post_id).to eq(post.id)
      expect(history.cluster_id).to eq(cluster.id)
    end

    it 'invalidates state cache' do
      expect(ContentStrategy::StateCache).to receive(:invalidate).with(persona.id)
      strategy.after_post(post: post, photo: photo, cluster: cluster)
    end
  end

  describe '#name' do
    it 'returns underscored class name' do
      expect(strategy.name).to match(/strategy/)
    end
  end

  describe '#build_decision_context' do
    let(:photo) { FactoryBot.create(:photo) }
    let(:cluster) { FactoryBot.create(:cluster) }

    it 'includes photo and cluster ids' do
      context_hash = strategy.send(:build_decision_context, photo: photo, cluster: cluster)
      
      expect(context_hash[:photo_id]).to eq(photo.id)
      expect(context_hash[:cluster_id]).to eq(cluster.id)
    end

    it 'includes timestamp' do
      context_hash = strategy.send(:build_decision_context, photo: photo, cluster: cluster)
      
      expect(context_hash[:timestamp]).to be_present
    end
  end
end
