# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clustering::RenameCluster do
  describe '#call' do
    let(:cluster) { FactoryBot.create(:cluster, name: 'Old Name') }

    context 'when cluster_id is not provided' do
      it 'returns failure with validation error' do
        result = described_class.call(new_name: 'New Name')

        expect(result).not_to be_success
        expect(result.full_error_message).to include("missing keyword")
      end
    end

    context 'when new_name is not provided' do
      it 'returns failure with validation error' do
        result = described_class.call(cluster_id: cluster.id)

        expect(result).not_to be_success
        expect(result.full_error_message).to include("missing keyword")
      end
    end

    context 'when both parameters are missing' do
      it 'returns failure with both validation errors' do
        result = described_class.call

        expect(result).not_to be_success
        expect(result.full_error_message).to include("missing keyword")
      end
    end

    context 'when cluster does not exist' do
      it 'returns failure with not found message' do
        result = described_class.call(cluster_id: 999, new_name: 'New Name')

        expect(result).not_to be_success
        expect(result.full_error_message).to include('Cluster not found')
      end
    end

    context 'when cluster exists with valid parameters' do
      it 'returns success' do
        result = described_class.call(cluster_id: cluster.id, new_name: 'Cyberpunk Nights')

        expect(result).to be_success
      end

      it 'updates the cluster name' do
        described_class.call(cluster_id: cluster.id, new_name: 'Cyberpunk Nights')

        cluster.reload
        expect(cluster.name).to eq('Cyberpunk Nights')
      end

      it 'persists the change to the database' do
        described_class.call(cluster_id: cluster.id, new_name: 'Nature Landscapes')

        reloaded_cluster = Clustering::Cluster.find(cluster.id)
        expect(reloaded_cluster.name).to eq('Nature Landscapes')
      end

      it 'returns confirmation message with cluster ID and new name' do
        result = described_class.call(cluster_id: cluster.id, new_name: 'Urban Photography')

        expect(result.message).to include("Successfully renamed cluster #{cluster.id}")
        expect(result.message).to include("'Urban Photography'")
      end

      it 'can rename from nil to a name' do
        unnamed_cluster = FactoryBot.create(:cluster, name: nil)

        result = described_class.call(cluster_id: unnamed_cluster.id, new_name: 'First Name')

        expect(result).to be_success
        unnamed_cluster.reload
        expect(unnamed_cluster.name).to eq('First Name')
      end

      it 'can rename a cluster multiple times' do
        described_class.call(cluster_id: cluster.id, new_name: 'First Rename')
        cluster.reload
        expect(cluster.name).to eq('First Rename')

        described_class.call(cluster_id: cluster.id, new_name: 'Second Rename')
        cluster.reload
        expect(cluster.name).to eq('Second Rename')
      end

      it 'does not affect other cluster attributes' do
        original_status = cluster.status
        original_photos_count = cluster.photos_count
        original_created_at = cluster.created_at

        described_class.call(cluster_id: cluster.id, new_name: 'New Name')

        cluster.reload
        expect(cluster.status).to eq(original_status)
        expect(cluster.photos_count).to eq(original_photos_count)
        expect(cluster.created_at).to eq(original_created_at)
      end
    end
  end
end
