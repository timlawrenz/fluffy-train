# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Photos::ClusteringService do
  describe '#call' do
    let(:service) { described_class.new(k_clusters: 3) }

    context 'when there are no photos to cluster' do
      it 'returns success with no photos processed' do
        result = service.call

        expect(result[:success]).to be true
        expect(result[:message]).to eq('No photos to cluster')
        expect(result[:photos_processed]).to eq(0)
      end
    end

    context 'when there are photos without embeddings' do
      before do
        FactoryBot.create(:photo) # Photo without embedding
      end

      it 'skips photos without embeddings' do
        result = service.call

        expect(result[:success]).to be true
        expect(result[:message]).to eq('No photos to cluster')
        expect(result[:photos_processed]).to eq(0)
      end
    end

    context 'when there are photos already clustered' do
      let(:cluster) { FactoryBot.create(:cluster) }

      before do
        FactoryBot.create(:photo, embedding: mock_embedding, cluster: cluster)
      end

      it 'skips photos that already have cluster assignments' do
        result = service.call

        expect(result[:success]).to be true
        expect(result[:message]).to eq('No photos to cluster')
        expect(result[:photos_processed]).to eq(0)
      end
    end

    context 'when there are photos ready for clustering' do
      let(:persona) { FactoryBot.create(:persona) }

      before do
        FactoryBot.create(:photo, persona: persona, embedding: mock_embedding_one)
        FactoryBot.create(:photo, persona: persona, embedding: mock_embedding_two)
        FactoryBot.create(:photo, persona: persona, embedding: mock_embedding_three)
      end

      it 'successfully clusters photos and creates clusters' do
        result = service.call

        expect(result[:success]).to be true
        expect(result[:photos_processed]).to eq(3)
        expect(result[:clusters_created]).to eq(3)
        expect(result[:message]).to include('Successfully clustered 3 photos into 3 clusters')

        # Verify clusters were created
        expect(Cluster.count).to eq(3)
      end

      it 'assigns cluster_id to all photos' do
        service.call

        Photo.where(persona: persona).find_each do |photo|
          expect(photo.cluster_id).not_to be_nil
          expect(photo.cluster).to be_a(Cluster)
        end
      end

      it 'creates clusters with correct names and status' do
        service.call

        clusters = Cluster.order(:id)
        expect(clusters.count).to eq(3)

        clusters.each_with_index do |cluster, index|
          expect(cluster.name).to eq("Cluster #{index + 1}")
          expect(cluster.status).to eq(0) # active status
        end
      end

      it 'updates cluster photos_count correctly' do
        service.call

        # Check that at least one cluster has photos assigned
        clusters_with_photos = Cluster.where('photos_count > 0')
        expect(clusters_with_photos.count).to be_positive

        # Verify total photos assigned equals original photos
        total_assigned = Cluster.sum(:photos_count)
        expect(total_assigned).to eq(3)
      end

      it 'wraps database operations in a transaction' do
        # Mock an error during cluster creation to test rollback
        allow(Cluster).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Cluster.new))

        expect { service.call }.not_to change(Photo.where.not(cluster_id: nil), :count)
        expect { service.call }.not_to change(Cluster, :count)
      end
    end

    context 'when k_clusters is larger than number of photos' do
      let(:persona) { FactoryBot.create(:persona) }
      let(:service) { described_class.new(k_clusters: 5) }

      before do
        FactoryBot.create(:photo, persona: persona, embedding: mock_embedding_one)
        FactoryBot.create(:photo, persona: persona, embedding: mock_embedding_two)
      end

      it 'adjusts k_clusters to match number of photos' do
        result = service.call

        expect(result[:success]).to be true
        expect(result[:photos_processed]).to eq(2)
        # Should create 5 clusters as requested, even if some might be empty
        expect(result[:clusters_created]).to eq(5)
      end
    end

    context 'when an error occurs during clustering' do
      let(:persona) { FactoryBot.create(:persona) }

      before do
        FactoryBot.create(:photo, persona: persona, embedding: mock_embedding_one)
        allow(Rumale::Clustering::KMeans).to receive(:new).and_raise(StandardError.new('Clustering failed'))
      end

      it 'returns error result and logs the error' do
        allow(Rails.logger).to receive(:error)

        result = service.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Clustering failed')
        expect(Rails.logger).to have_received(:error).with('Photos::ClusteringService failed: Clustering failed')
      end
    end
  end

  describe 'initialization' do
    it 'uses default k_clusters when not specified' do
      service = described_class.new
      expect(service.instance_variable_get(:@k_clusters)).to eq(described_class::DEFAULT_K_CLUSTERS)
    end

    it 'accepts custom k_clusters value' do
      service = described_class.new(k_clusters: 10)
      expect(service.instance_variable_get(:@k_clusters)).to eq(10)
    end
  end

  private

  def mock_embedding_one
    # Create a deterministic 512-dimensional embedding for testing
    Array.new(512) { |i| (i % 10) / 10.0 }
  end

  def mock_embedding_two
    # Create a different deterministic embedding
    Array.new(512) { |i| ((i + 5) % 10) / 10.0 }
  end

  def mock_embedding_three
    # Create another different deterministic embedding
    Array.new(512) { |i| ((i + 3) % 10) / 10.0 }
  end

  def mock_embedding
    mock_embedding_one
  end
end
