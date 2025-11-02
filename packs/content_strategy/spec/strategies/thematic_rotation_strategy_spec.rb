require 'rails_helper'

RSpec.describe ContentStrategy::ThematicRotationStrategy do
  let(:persona) { create(:persona) }
  let(:config) { ContentStrategy::ConfigLoader.load }
  let(:context) { ContentStrategy::Context.new(persona: persona, config: config) }
  let(:strategy) { described_class.new(context: context) }

  describe '#select_next_photo' do
    context 'with multiple clusters' do
      let!(:cluster1) { create(:cluster, persona: persona, name: 'Mountains') }
      let!(:cluster2) { create(:cluster, persona: persona, name: 'Cities') }
      let!(:photo1) { create(:photo, cluster: cluster1, persona: persona) }
      let!(:photo2) { create(:photo, cluster: cluster2, persona: persona) }

      it 'returns success with photo and cluster' do
        result = strategy.select_next_photo

        expect(result[:photo]).to be_in([photo1, photo2])
        expect(result[:cluster]).to be_in([cluster1, cluster2])
        expect(result[:optimal_time]).to be_present
        expect(result[:hashtags]).to be_an(Array)
      end

      it 'rotates through clusters' do
        result1 = strategy.select_next_photo
        cluster_id1 = result1[:cluster].id

        # Simulate after_post callback
        post = create(:scheduling_post, persona: persona, photo: result1[:photo])
        strategy.after_post(post: post, photo: result1[:photo], cluster: result1[:cluster])

        # Second selection should be different cluster (if available)
        new_context = ContentStrategy::Context.new(persona: persona, config: config)
        new_strategy = described_class.new(context: new_context)
        result2 = new_strategy.select_next_photo

        # Rotation index should have advanced
        state = ContentStrategy::StrategyState.find_by(persona: persona)
        expect(state.get_state(:rotation_index)).to eq(1)
      end
    end

    context 'when max weekly posts reached' do
      let!(:cluster) { create(:cluster, persona: persona) }
      let!(:photo) { create(:photo, cluster: cluster, persona: persona) }

      before do
        5.times do
          post = create(:scheduling_post, persona: persona, photo: photo)
          ContentStrategy::HistoryRecord.create!(
            persona: persona,
            post: post,
            cluster: cluster,
            strategy_name: 'thematic_rotation_strategy'
          )
        end
      end

      it 'returns error for max weekly posts' do
        result = strategy.select_next_photo

        expect(result[:error]).to include('Max weekly posts reached')
      end
    end

    context 'with no clusters' do
      it 'returns error' do
        result = strategy.select_next_photo

        expect(result[:error]).to include('No clusters available')
      end
    end
  end

  describe '#select_next_cluster' do
    let!(:cluster1) { create(:cluster, persona: persona, name: 'A') }
    let!(:cluster2) { create(:cluster, persona: persona, name: 'B') }
    let!(:cluster3) { create(:cluster, persona: persona, name: 'C') }

    it 'returns cluster based on rotation index' do
      cluster = strategy.send(:select_next_cluster)
      expect([cluster1, cluster2, cluster3]).to include(cluster)
    end

    it 'wraps around when reaching end' do
      state = ContentStrategy::StrategyState.find_or_create_by!(persona: persona)
      state.set_state(:rotation_index, 2)

      cluster = strategy.send(:select_next_cluster)
      expect(cluster).to eq(cluster3)

      # Next should wrap to first
      state.set_state(:rotation_index, 3)
      cluster = strategy.send(:select_next_cluster)
      expect(cluster).to eq(cluster1)
    end
  end

  describe '#get_rotation_index' do
    it 'returns 0 for new strategy' do
      expect(strategy.send(:get_rotation_index)).to eq(0)
    end

    it 'returns saved index' do
      state = ContentStrategy::StrategyState.find_or_create_by!(persona: persona)
      state.set_state(:rotation_index, 5)

      new_context = ContentStrategy::Context.new(persona: persona)
      new_strategy = described_class.new(context: new_context)

      expect(new_strategy.send(:get_rotation_index)).to eq(5)
    end
  end

  describe '#advance_rotation_index' do
    let(:cluster) { create(:cluster, persona: persona) }

    it 'increments rotation index' do
      expect {
        strategy.send(:advance_rotation_index, cluster)
      }.to change { strategy.send(:get_rotation_index) }.from(0).to(1)
    end
  end

  describe '#after_post' do
    let(:cluster) { create(:cluster, persona: persona) }
    let(:photo) { create(:photo, cluster: cluster, persona: persona) }
    let(:post) { create(:scheduling_post, persona: persona, photo: photo) }

    it 'records history' do
      expect {
        strategy.after_post(post: post, photo: photo, cluster: cluster)
      }.to change { ContentStrategy::HistoryRecord.count }.by(1)
    end

    it 'advances rotation index' do
      expect {
        strategy.after_post(post: post, photo: photo, cluster: cluster)
      }.to change { strategy.send(:get_rotation_index) }.by(1)
    end

    it 'invalidates cache' do
      expect(ContentStrategy::StateCache).to receive(:invalidate).with(persona.id)
      strategy.after_post(post: post, photo: photo, cluster: cluster)
    end
  end
end
