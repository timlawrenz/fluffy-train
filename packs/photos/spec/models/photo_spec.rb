# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Photo do
  describe 'associations' do
    it 'belongs to a persona' do
      expect(described_class.reflect_on_association(:persona)).to be_a(ActiveRecord::Reflection::BelongsToReflection)
    end

    it 'has one photo analysis' do
      association = described_class.reflect_on_association(:photo_analysis)
      expect(association).to be_a(ActiveRecord::Reflection::HasOneReflection)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe 'validations' do
    let(:photo) { FactoryBot.build(:photo) }

    it 'is valid with valid attributes' do
      expect(photo).to be_valid
    end

    it 'requires a path' do
      photo.path = nil
      expect(photo).not_to be_valid
      expect(photo.errors[:path]).to include("can't be blank")
    end

    it 'requires a unique path' do
      existing_photo = FactoryBot.create(:photo)
      duplicate_photo = FactoryBot.build(:photo, path: existing_photo.path)
      expect(duplicate_photo).not_to be_valid
      expect(duplicate_photo.errors[:path]).to include('has already been taken')
    end
  end
end
