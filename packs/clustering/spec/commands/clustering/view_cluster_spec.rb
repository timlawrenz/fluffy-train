# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'rails_helper'
require_relative '../../../app/commands/clustering/view_cluster'
require_relative '../../../app/models/clustering/cluster'

RSpec.describe Clustering::ViewCluster do
  # Mock the cluster model
  let(:cluster_double) { double('Clustering::Cluster') }
  let(:first_photo) { double('Photo', path: '/path/to/photo1.jpg') }
  let(:second_photo) { double('Photo', path: '/path/to/photo2.jpg') }
  let(:third_photo) { double('Photo', path: '/path/to/photo3.jpg') }
  let(:photos_collection) { [first_photo, second_photo, third_photo] }
  let(:photos_relation) { double('Photos Relation') }

  before do
    # Create a mock class that responds to find_by
    mock_cluster_class = Class.new do
      def self.find_by(*)
        # This will be stubbed in individual tests
      end
    end

    # Stub the Clustering::Cluster model with our mock
    stub_const('Clustering::Cluster', mock_cluster_class)

    # Stub the photos association
    allow(cluster_double).to receive(:photos).and_return(photos_relation)
    allow(photos_relation).to receive_messages(
      where: photos_relation,
      not: photos_relation,
      limit: photos_collection
    )
    allow(photos_collection).to receive(:sample).and_return(photos_collection)

    # Mock file system operations
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:cp)
    allow(File).to receive_messages(
      exist?: true,
      extname: '.jpg',
      basename: 'photo'
    )
  end

  describe '#call' do
    context 'with valid cluster_id' do
      let(:cluster_id) { 1 }

      before do
        allow(Clustering::Cluster).to receive(:find_by).with(id: cluster_id).and_return(cluster_double)
      end

      it 'is successful' do
        result = described_class.call(cluster_id: cluster_id)
        expect(result).to be_success
      end

      it 'returns the output path' do
        result = described_class.call(cluster_id: cluster_id)
        expect(result.output_path).to eq('/tmp/cluster_samples/cluster_1')
      end

      it 'creates the output directory' do
        described_class.call(cluster_id: cluster_id)
        expect(FileUtils).to have_received(:mkdir_p).with('/tmp/cluster_samples/cluster_1')
      end

      it 'copies the correct number of files' do
        described_class.call(cluster_id: cluster_id)
        expect(FileUtils).to have_received(:cp).exactly(3).times
      end

      it 'copies files with correct naming convention' do
        allow(File).to receive(:extname).with('/path/to/photo1.jpg').and_return('.jpg')
        allow(File).to receive(:extname).with('/path/to/photo2.jpg').and_return('.jpg')
        allow(File).to receive(:extname).with('/path/to/photo3.jpg').and_return('.jpg')
        allow(File).to receive(:basename).with('/path/to/photo1.jpg', '.jpg').and_return('photo1')
        allow(File).to receive(:basename).with('/path/to/photo2.jpg', '.jpg').and_return('photo2')
        allow(File).to receive(:basename).with('/path/to/photo3.jpg', '.jpg').and_return('photo3')

        described_class.call(cluster_id: cluster_id)
        expect(FileUtils).to have_received(:cp).with('/path/to/photo1.jpg',
                                                     '/tmp/cluster_samples/cluster_1/1_photo1.jpg')
        expect(FileUtils).to have_received(:cp).with('/path/to/photo2.jpg',
                                                     '/tmp/cluster_samples/cluster_1/2_photo2.jpg')
        expect(FileUtils).to have_received(:cp).with('/path/to/photo3.jpg',
                                                     '/tmp/cluster_samples/cluster_1/3_photo3.jpg')
      end

      context 'with custom sample_size' do
        let(:sample_size) { 2 }

        before do
          allow(photos_collection).to receive(:sample).with(2).and_return([first_photo, second_photo])
        end

        it 'uses the custom sample size' do
          described_class.call(cluster_id: cluster_id, sample_size: sample_size)
          expect(photos_collection).to have_received(:sample).with(2)
        end

        it 'copies only the sampled files' do
          described_class.call(cluster_id: cluster_id, sample_size: sample_size)
          expect(FileUtils).to have_received(:cp).exactly(2).times
        end
      end

      context 'when some photo files do not exist' do
        before do
          allow(File).to receive(:exist?).with('/path/to/photo1.jpg').and_return(true)
          allow(File).to receive(:exist?).with('/path/to/photo2.jpg').and_return(false)
          allow(File).to receive(:exist?).with('/path/to/photo3.jpg').and_return(true)
        end

        it 'only copies existing files' do
          allow(File).to receive(:extname).with('/path/to/photo1.jpg').and_return('.jpg')
          allow(File).to receive(:extname).with('/path/to/photo3.jpg').and_return('.jpg')
          allow(File).to receive(:basename).with('/path/to/photo1.jpg', '.jpg').and_return('photo1')
          allow(File).to receive(:basename).with('/path/to/photo3.jpg', '.jpg').and_return('photo3')

          described_class.call(cluster_id: cluster_id)
          expect(FileUtils).to have_received(:cp).exactly(2).times
          expect(FileUtils).to have_received(:cp).with('/path/to/photo1.jpg',
                                                       '/tmp/cluster_samples/cluster_1/1_photo1.jpg')
          expect(FileUtils).to have_received(:cp).with('/path/to/photo3.jpg',
                                                       '/tmp/cluster_samples/cluster_1/3_photo3.jpg')
        end
      end
    end

    context 'with invalid inputs' do
      context 'when cluster_id is nil' do
        it 'fails with appropriate error message' do
          result = described_class.call(cluster_id: nil)
          expect(result).to be_failure
          expect(result.errors[:base]).to include('Command Error: cluster_id is required')
        end
      end

      context 'when cluster_id is not an integer' do
        it 'fails with appropriate error message' do
          result = described_class.call(cluster_id: 'invalid')
          expect(result).to be_failure
          expect(result.errors[:base]).to include('Command Error: cluster_id must be an integer')
        end
      end

      context 'when sample_size is not an integer' do
        it 'fails with appropriate error message' do
          result = described_class.call(cluster_id: 1, sample_size: 'invalid')
          expect(result).to be_failure
          expect(result.errors[:base]).to include('Command Error: sample_size must be an integer')
        end
      end

      context 'when sample_size is not positive' do
        it 'fails with appropriate error message' do
          result = described_class.call(cluster_id: 1, sample_size: 0)
          expect(result).to be_failure
          expect(result.errors[:base]).to include('Command Error: sample_size must be positive')
        end
      end
    end

    context 'when cluster is not found' do
      before do
        allow(Clustering::Cluster).to receive(:find_by).with(id: 999).and_return(nil)
      end

      it 'fails with appropriate error message' do
        result = described_class.call(cluster_id: 999)
        expect(result).to be_failure
        expect(result.errors[:base]).to include('Command Error: Cluster with ID 999 not found')
      end
    end

    context 'when cluster has no photos' do
      before do
        allow(Clustering::Cluster).to receive(:find_by).with(id: 1).and_return(cluster_double)
        allow(photos_collection).to receive(:sample).and_return([])
      end

      it 'fails with appropriate error message' do
        result = described_class.call(cluster_id: 1)
        expect(result).to be_failure
        expect(result.errors[:base]).to include('Command Error: No photos found in cluster 1')
      end
    end

    context 'when using default sample_size' do
      let(:cluster_id) { 1 }

      before do
        allow(Clustering::Cluster).to receive(:find_by).with(id: cluster_id).and_return(cluster_double)
      end

      it 'uses default sample size of 10' do
        described_class.call(cluster_id: 1)
        expect(photos_collection).to have_received(:sample).with(10)
      end
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
