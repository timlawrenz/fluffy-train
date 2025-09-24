# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'spec_helper'

require_relative '../../../app/commands/photos/create_photo_analysis'

RSpec.describe Photos::CreatePhotoAnalysis, type: :command do
  let(:photo) { double('Photo', id: 1, class: Photo) }
  let(:sharpness_score) { 85.5 }
  let(:exposure_score) { 0.75 }
  let(:aesthetic_score) { 7.2 }
  let(:detected_objects) { [{ 'label' => 'tree', 'confidence' => 0.95 }] }
  let(:photo_analysis) { double('PhotoAnalysis', id: 1) }

  before do
    photo_analysis_class = Class.new do
      def self.create!(**args)
        # This will be stubbed in individual tests
      end
    end
    stub_const('Photo', Class.new)
    stub_const('PhotoAnalysis', photo_analysis_class)
    allow(PhotoAnalysis).to receive(:create!).and_return(photo_analysis)
    allow(photo).to receive(:class).and_return(double('PhotoClass', name: 'Photo'))
  end

  describe '#call' do
    context 'when successful' do
      it 'succeeds' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_success
      end

      it 'creates a PhotoAnalysis record with correct attributes' do
        expect(PhotoAnalysis).to receive(:create!).with(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )

        described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
      end

      it 'returns the created PhotoAnalysis record' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result.photo_analysis).to eq(photo_analysis)
      end
    end

    context 'when photo is invalid' do
      let(:invalid_photo) { double('NotAPhoto', class: double('StringClass', name: 'String')) }

      it 'fails with validation error' do
        result = described_class.call(
          photo: invalid_photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_failure
        expect(result.full_error_message).to match(/Invalid photo: expected Photo object, got.*StringClass/)
      end
    end

    context 'when PhotoAnalysis creation fails' do
      let(:record_invalid_error) { ActiveRecord::RecordInvalid.new(photo_analysis) }

      before do
        stub_const('ActiveRecord::RecordInvalid', Class.new(StandardError))
        allow(PhotoAnalysis).to receive(:create!).and_raise(record_invalid_error)
        allow(record_invalid_error).to receive(:message).and_return('validation failed')
      end

      it 'fails with appropriate error message' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Failed to create PhotoAnalysis record: validation failed')
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow(PhotoAnalysis).to receive(:create!).and_raise(StandardError, 'Unexpected error')
      end

      it 'fails with appropriate error message' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Unexpected error creating PhotoAnalysis record: Unexpected error')
      end
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles