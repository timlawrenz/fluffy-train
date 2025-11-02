require 'rails_helper'

RSpec.describe ContentStrategy::ThemeOfWeekStrategy do
  let(:persona) { create(:persona) }
  let(:config) { ContentStrategy::ConfigLoader.load }
  let(:context) { ContentStrategy::Context.new(persona: persona, config: config) }
  let(:strategy) { described_class.new(context: context) }

  describe '#select_next_photo' do
    context 'with available clusters and photos' do
      let!(:cluster) { create(:cluster, persona: persona, name: 'Mountains') }
      let!(:photo) { create(:photo, cluster: cluster, persona: persona) }

      it 'returns success with photo and cluster' do
        result = strategy.select_next_photo

        expect(result[:photo]).to eq(photo)
        expect(result[:cluster]).to eq(cluster)
        expect(result[:optimal_time]).to be_present
        expect(result[:hashtags]).to be_an(Array)
        expect(result[:format]).to be_in([:static, :carousel, :reel])
      end

      it 'sets strategy state with week and cluster' do
        strategy.select_next_photo
        state = ContentStrategy::StrategyState.find_by(persona: persona)

        expect(state.get_state(:week_number)).to match(/\d{4}-W\d{2}/)
        expect(state.get_state(:cluster_id)).to eq(cluster.id)
      end
    end

    context 'when max weekly posts reached' do
      let!(:cluster) { create(:cluster, persona: persona) }
      let!(:photo) { create(:photo, cluster: cluster, persona: persona) }

      before do
        # Create 5 posts this week (max is 5)
        5.times do
          post = create(:scheduling_post, persona: persona, photo: photo)
          ContentStrategy::HistoryRecord.create!(
            persona: persona,
            post: post,
            cluster: cluster,
            strategy_name: 'theme_of_week_strategy'
          )
        end
      end

      it 'returns error for max weekly posts' do
        result = strategy.select_next_photo

        expect(result[:error]).to include('Max weekly posts reached')
      end
    end

    context 'when cluster exhausted' do
      let!(:cluster) { create(:cluster, persona: persona) }
      let!(:photo) { create(:photo, cluster: cluster, persona: persona) }
      let!(:post) { create(:scheduling_post, persona: persona, photo: photo) }

      it 'returns error for no available photos' do
        result = strategy.select_next_photo

        expect(result[:error]).to include('No photos available')
      end
    end

    context 'with no clusters' do
      it 'returns error for no clusters' do
        result = strategy.select_next_photo

        expect(result[:error]).to include('No cluster available')
      end
    end

    context 'week boundary transition' do
      let!(:cluster1) { create(:cluster, persona: persona, name: 'Mountains') }
      let!(:cluster2) { create(:cluster, persona: persona, name: 'Cities') }
      let!(:photo1) { create(:photo, cluster: cluster1, persona: persona) }
      let!(:photo2) { create(:photo, cluster: cluster2, persona: persona) }

      it 'switches cluster on new week' do
        # Week 1
        result1 = strategy.select_next_photo
        week1_cluster = result1[:cluster]

        # Simulate week change
        state = ContentStrategy::StrategyState.find_by(persona: persona)
        state.set_state(:week_number, '2024-W01')

        # Week 2 - should get different cluster
        new_context = ContentStrategy::Context.new(persona: persona, config: config)
        new_strategy = described_class.new(context: new_context)
        result2 = new_strategy.select_next_photo

        expect(result2[:cluster]).not_to eq(week1_cluster)
      end
    end
  end

  describe '#get_or_set_weekly_cluster' do
    let!(:cluster) { create(:cluster, persona: persona) }

    it 'creates state for new week' do
      expect {
        strategy.send(:get_or_set_weekly_cluster)
      }.to change { ContentStrategy::StrategyState.count }.by(1)
    end

    it 'returns same cluster within same week' do
      cluster1 = strategy.send(:get_or_set_weekly_cluster)
      cluster2 = strategy.send(:get_or_set_weekly_cluster)

      expect(cluster1).to eq(cluster2)
    end
  end

  describe '#select_new_cluster' do
    let!(:cluster1) { create(:cluster, persona: persona, name: 'Mountains') }
    let!(:cluster2) { create(:cluster, persona: persona, name: 'Cities') }

    it 'selects from available clusters' do
      cluster = strategy.send(:select_new_cluster)

      expect([cluster1, cluster2]).to include(cluster)
    end

    it 'returns nil when no clusters available' do
      Cluster.destroy_all

      expect(strategy.send(:select_new_cluster)).to be_nil
    end
  end
end
