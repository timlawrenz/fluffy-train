# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhotoAnalysis do
  describe 'associations' do
    it 'belongs to a photo' do
      expect(described_class.reflect_on_association(:photo)).to be_a(ActiveRecord::Reflection::BelongsToReflection)
    end
  end

  describe 'validations' do
    let(:photo_analysis) { FactoryBot.build(:photo_analysis) }

    it 'is valid with valid attributes' do
      expect(photo_analysis).to be_valid
    end

    it 'is not valid without a photo' do
      photo_analysis.photo = nil
      expect(photo_analysis).not_to be_valid
      expect(photo_analysis.errors[:photo]).to include('must exist')
    end
  end

  describe 'attributes' do
    let(:photo_analysis) { FactoryBot.create(:photo_analysis) }

    it 'can store sharpness score' do
      photo_analysis.sharpness_score = 0.85
      photo_analysis.save!
      expect(photo_analysis.reload.sharpness_score).to eq(0.85)
    end

    it 'can store exposure score' do
      photo_analysis.exposure_score = 0.75
      photo_analysis.save!
      expect(photo_analysis.reload.exposure_score).to eq(0.75)
    end

    it 'can store aesthetic score' do
      photo_analysis.aesthetic_score = 0.90
      photo_analysis.save!
      expect(photo_analysis.reload.aesthetic_score).to eq(0.90)
    end

    it 'can store detected objects as jsonb' do
      objects = [{ 'object' => 'person', 'confidence' => 0.95 }]
      photo_analysis.detected_objects = objects
      photo_analysis.save!
      expect(photo_analysis.reload.detected_objects).to eq(objects)
    end
  end
end
