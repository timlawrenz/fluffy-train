# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clustering::ListClusters do
  describe '#call' do
    context 'when no clusters exist' do
      before do
        Clustering::Cluster.destroy_all
      end

      it 'returns success with no clusters message' do
        result = described_class.call

        expect(result).to be_success
        expect(result.message).to eq('No clusters found')
      end

      it 'prints no clusters message to console' do
        expect { described_class.call }.to output(/No clusters found/).to_stdout
      end
    end

    context 'when clusters exist' do
      let!(:cluster1) { FactoryBot.create(:cluster, name: 'Nature Scenes', photos_count: 42) }
      let!(:cluster2) { FactoryBot.create(:cluster, name: 'Urban Photography', photos_count: 87) }
      let!(:cluster3) { FactoryBot.create(:cluster, name: nil, photos_count: 15) }

      it 'returns success with cluster count' do
        result = described_class.call

        expect(result).to be_success
        expect(result.message).to eq('Listed 3 clusters')
      end

      it 'prints formatted table with cluster information' do
        output = capture_stdout { described_class.call }

        expect(output).to include('ID')
        expect(output).to include('Name')
        expect(output).to include('Photos')
        expect(output).to include('Nature Scenes')
        expect(output).to include('42')
        expect(output).to include('Urban Photography')
        expect(output).to include('87')
        expect(output).to include('(unnamed)')
        expect(output).to include('15')
      end

      it 'orders clusters by ID' do
        output = capture_stdout { described_class.call }

        # Check that cluster1 appears before cluster2 in output
        cluster1_position = output.index(cluster1.id.to_s)
        cluster2_position = output.index(cluster2.id.to_s)
        expect(cluster1_position).to be < cluster2_position
      end
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
