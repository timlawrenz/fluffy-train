# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clustering::Cluster do
  describe 'associations' do
    it 'has many photos' do
      association = described_class.reflect_on_association(:photos)
      expect(association).to be_a(ActiveRecord::Reflection::HasManyReflection)
      expect(association.options[:dependent]).to eq(:nullify)
    end
  end

  describe 'factory' do
    let(:cluster) { FactoryBot.build(:cluster) }

    it 'is valid with valid attributes' do
      expect(cluster).to be_valid
    end

    it 'has default values' do
      cluster = FactoryBot.create(:cluster)
      expect(cluster.status).to eq(0)
      expect(cluster.photos_count).to eq(0)
    end
  end

  describe 'photo association behavior' do
    it 'can have photos associated with it' do
      cluster = FactoryBot.create(:cluster)
      photo = FactoryBot.create(:photo, cluster: cluster)

      expect(cluster.photos).to include(photo)
      expect(photo.cluster).to eq(cluster)
    end

    it 'nullifies cluster_id when cluster is deleted' do
      cluster = FactoryBot.create(:cluster)
      photo = FactoryBot.create(:photo, cluster: cluster)

      expect(photo.cluster).to eq(cluster)

      cluster.destroy
      photo.reload

      expect(photo.cluster).to be_nil
    end

    it 'updates photos_count when photos are added or removed' do
      cluster = FactoryBot.create(:cluster)

      expect(cluster.photos_count).to eq(0)

      photo1 = FactoryBot.create(:photo, cluster: cluster)
      cluster.reload
      expect(cluster.photos_count).to eq(1)

      photo2 = FactoryBot.create(:photo, cluster: cluster)
      cluster.reload
      expect(cluster.photos_count).to eq(2)

      photo1.destroy
      cluster.reload
      expect(cluster.photos_count).to eq(1)

      photo2.update!(cluster: nil)
      cluster.reload
      expect(cluster.photos_count).to eq(0)
    end
  end
end
