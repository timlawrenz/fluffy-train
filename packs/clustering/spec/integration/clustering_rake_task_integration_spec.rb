# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'clustering:generate Rake Task Integration', type: :integration do
  # This integration test verifies the Rake task behavior by testing the interface
  # and expected outcomes with actual database operations

  describe 'rake task interface validation' do
    it 'exists and has the expected structure' do
      # Test that the task file exists and can be loaded
      rake_file = Rails.root.join('packs/clustering/lib/tasks/clustering.rake')
      expect(File.exist?(rake_file)).to be true

      # Verify the task file contains expected structure
      rake_content = File.read(rake_file)
      expect(rake_content).to include('namespace :clustering')
      expect(rake_content).to include('task generate: :environment')
      expect(rake_content).to include('Clustering::ClusteringService')
    end

    it 'includes expected behavior patterns' do
      # Load task file without executing to test interface
      rake_content = File.read(Rails.root.join('packs/clustering/lib/tasks/clustering.rake'))

      # Verify the task includes service instantiation
      expect(rake_content).to include('Clustering::ClusteringService.new')
      expect(rake_content).to include('clustering_service.call')

      # Verify error handling
      expect(rake_content).to include('exit 1')
      expect(rake_content).to include('Error:')
    end
  end

  describe 'task execution with database operations' do
    let(:persona) { FactoryBot.create(:persona) }
    let(:embedding_one) { Array.new(512) { |i| (i % 10) / 10.0 } }
    let(:embedding_two) { Array.new(512) { |i| ((i + 5) % 10) / 10.0 } }
    let(:embedding_three) { Array.new(512) { |i| ((i + 3) % 10) / 10.0 } }

    before do
      # Clear any existing data
      Photo.destroy_all
      Clustering::Cluster.destroy_all

      # Load the rake task
      Rails.application.load_tasks
    end

    context 'when there are photos with embeddings to cluster' do
      let!(:photo_with_embedding_one) do
        FactoryBot.create(:photo, persona: persona, embedding: embedding_one, cluster_id: nil)
      end
      let!(:photo_with_embedding_two) do
        FactoryBot.create(:photo, persona: persona, embedding: embedding_two, cluster_id: nil)
      end
      let!(:photo_with_embedding_three) do
        FactoryBot.create(:photo, persona: persona, embedding: embedding_three, cluster_id: nil)
      end

      after do
        # Clear the rake task to allow re-invocation in other tests
        Rake::Task['clustering:generate'].reenable
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'successfully executes the rake task and creates clusters' do
        # Capture stdout to verify task output
        output = capture_stdout do
          Rake::Task['clustering:generate'].invoke
        end

        expect(output).to include('Starting photo clustering process...')
        expect(output).to include('Successfully clustered 3 photos')
        expect(output).to include('Photos processed: 3')
        expect(output).to include('Clusters created:')

        # Verify clusters were created
        expect(Clustering::Cluster.count).to eq(3)

        # Verify all photos have been assigned to clusters
        [photo_with_embedding_one, photo_with_embedding_two, photo_with_embedding_three].each do |photo|
          photo.reload
          expect(photo.cluster_id).not_to be_nil
          expect(photo.cluster).to be_a(Clustering::Cluster)
        end

        # Verify clusters have correct structure
        Clustering::Cluster.find_each do |cluster|
          expect(cluster.name).to match(/Cluster \d+/)
          expect(cluster.status).to eq(0) # active status
          expect(cluster.photos_count).to be_positive
        end

        # Verify total photos assigned equals original photos
        total_assigned = Clustering::Cluster.sum(:photos_count)
        expect(total_assigned).to eq(3)
      end
      # rubocop:enable RSpec/MultipleExpectations

      it 'handles the case where k_clusters is larger than number of photos' do
        # Create only 2 photos but use default k_clusters of 5
        Photo.destroy_all
        FactoryBot.create(:photo, persona: persona, embedding: embedding_one, cluster_id: nil)
        FactoryBot.create(:photo, persona: persona, embedding: embedding_two, cluster_id: nil)

        output = capture_stdout do
          Rake::Task['clustering:generate'].invoke
        end

        expect(output).to include('Successfully clustered 2 photos')
        expect(output).to include('Clusters created: 2')

        # Should create only 2 clusters when there are only 2 photos
        expect(Clustering::Cluster.count).to eq(2)
      end
    end

    context 'when there are no photos to cluster' do
      after do
        Rake::Task['clustering:generate'].reenable
      end

      before do
        # Ensure no photos exist with embeddings and no cluster assignments
        Photo.destroy_all
      end

      it 'completes successfully with appropriate message' do
        output = capture_stdout do
          Rake::Task['clustering:generate'].invoke
        end

        expect(output).to include('Starting photo clustering process...')
        expect(output).to include('No photos to cluster')

        # No clusters should be created
        expect(Clustering::Cluster.count).to eq(0)
      end
    end

    context 'when photos exist but without embeddings' do
      after do
        Rake::Task['clustering:generate'].reenable
      end

      let!(:photo_without_embedding) { FactoryBot.create(:photo, persona: persona, embedding: nil) }

      it 'skips photos without embeddings' do
        output = capture_stdout do
          Rake::Task['clustering:generate'].invoke
        end

        expect(output).to include('No photos to cluster')
        expect(Clustering::Cluster.count).to eq(0)

        # Photo should remain unchanged
        photo_without_embedding.reload
        expect(photo_without_embedding.cluster_id).to be_nil
      end
    end

    context 'when photos are already clustered' do
      after do
        Rake::Task['clustering:generate'].reenable
      end

      let(:existing_cluster) { FactoryBot.create(:cluster) }
      let!(:clustered_photo) do
        FactoryBot.create(:photo, persona: persona, embedding: embedding_one, cluster: existing_cluster)
      end

      it 'skips photos that already have cluster assignments' do
        output = capture_stdout do
          Rake::Task['clustering:generate'].invoke
        end

        expect(output).to include('No photos to cluster')

        # No new clusters should be created
        expect(Clustering::Cluster.count).to eq(1)

        # Photo should remain in original cluster
        clustered_photo.reload
        expect(clustered_photo.cluster_id).to eq(existing_cluster.id)
      end
    end

    context 'when clustering service fails' do
      after do
        Rake::Task['clustering:generate'].reenable
      end

      before do
        FactoryBot.create(:photo, persona: persona, embedding: embedding_one, cluster_id: nil)
        allow(Clustering::ClusteringService).to receive(:new).and_raise(StandardError.new('Service error'))
      end

      it 'exits with error code and displays error message' do
        output = capture_stdout do
          expect { Rake::Task['clustering:generate'].invoke }.to(
            raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
          )
        end

        expect(output).to include('Error: Failed to run clustering service: Service error')
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

  def capture_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end
end
# rubocop:enable RSpec/DescribeClass
