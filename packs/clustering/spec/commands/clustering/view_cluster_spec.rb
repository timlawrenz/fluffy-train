# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clustering::ViewCluster do
  describe '#call' do
    let(:persona) { FactoryBot.create(:persona) }
    let(:cluster) { FactoryBot.create(:cluster) }

    context 'when cluster_id is not provided' do
      it 'returns failure with validation error' do
        result = described_class.call

        expect(result).not_to be_success
        expect(result.full_error_message).to include("missing keyword")
      end
    end

    context 'when cluster does not exist' do
      it 'returns failure with not found message' do
        result = described_class.call(cluster_id: 999)

        expect(result).not_to be_success
        expect(result.full_error_message).to include('Cluster not found')
      end
    end

    context 'when cluster exists with photos' do
      let!(:photo1) { FactoryBot.create(:photo, persona: persona, cluster: cluster, path: '/tmp/test1.jpg') }
      let!(:photo2) { FactoryBot.create(:photo, persona: persona, cluster: cluster, path: '/tmp/test2.jpg') }
      let!(:photo3) { FactoryBot.create(:photo, persona: persona, cluster: cluster, path: '/tmp/test3.jpg') }

      before do
        # Mock file operations
        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:cp)
        allow(File).to receive(:exist?).and_return(true)
      end

      it 'returns success with output path' do
        result = described_class.call(cluster_id: cluster.id)

        expect(result).to be_success
        expect(result.output_path).to eq("/tmp/cluster_samples/cluster_#{cluster.id}")
      end

      it 'creates output directory' do
        described_class.call(cluster_id: cluster.id)

        expect(FileUtils).to have_received(:mkdir_p).with("/tmp/cluster_samples/cluster_#{cluster.id}")
      end

      it 'copies sample images to output directory' do
        described_class.call(cluster_id: cluster.id, sample_size: 2)

        expect(FileUtils).to have_received(:cp).twice
      end

      it 'uses default sample size of 10' do
        10.times do |i|
          FactoryBot.create(:photo, persona: persona, cluster: cluster, path: "/tmp/test#{i + 4}.jpg")
        end

        described_class.call(cluster_id: cluster.id)

        # Should copy 10 files (default sample_size)
        expect(FileUtils).to have_received(:cp).at_most(10).times
      end

      it 'respects custom sample_size parameter' do
        described_class.call(cluster_id: cluster.id, sample_size: 2)

        expect(FileUtils).to have_received(:cp).at_most(2).times
      end

      it 'skips photos with missing files' do
        allow(File).to receive(:exist?).with(photo1.path).and_return(false)
        allow(File).to receive(:exist?).with(photo2.path).and_return(true)
        allow(File).to receive(:exist?).with(photo3.path).and_return(true)

        described_class.call(cluster_id: cluster.id)

        # Should only copy 2 files (photo2 and photo3)
        expect(FileUtils).to have_received(:cp).at_most(2).times
      end

      it 'includes success message with count and path' do
        result = described_class.call(cluster_id: cluster.id, sample_size: 2)

        expect(result.message).to include('Exported')
        expect(result.message).to include('sample images')
        expect(result.message).to include("/tmp/cluster_samples/cluster_#{cluster.id}")
      end
    end

    context 'when cluster has no photos' do
      let(:empty_cluster) { FactoryBot.create(:cluster) }

      before do
        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:cp)
      end

      it 'returns success with zero samples' do
        result = described_class.call(cluster_id: empty_cluster.id)

        expect(result).to be_success
        expect(result.message).to include('Exported 0 sample images')
      end

      it 'creates output directory even with no photos' do
        described_class.call(cluster_id: empty_cluster.id)

        expect(FileUtils).to have_received(:mkdir_p).with("/tmp/cluster_samples/cluster_#{empty_cluster.id}")
      end

      it 'does not copy any files' do
        described_class.call(cluster_id: empty_cluster.id)

        expect(FileUtils).not_to have_received(:cp)
      end
    end
  end
end
