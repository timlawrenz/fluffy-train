# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'spec_helper'
require 'gl_command/rspec'

require_relative '../../../../app/commands/photos/analyse/save_results'

RSpec.describe Photos::Analyse::SaveResults, type: :command do
  before do
    stub_const('Photo', Class.new)
    stub_const('PhotoAnalysis', Class.new do
      def self.create!(attributes)
        new(attributes)
      end

      def initialize(attributes)
        @attributes = attributes
      end

      attr_reader :attributes
    end)
    stub_const('Rails', Class.new do
      def self.logger
        @logger ||= double('Logger')
      end
    end)
  end

  let(:photo) { double('Photo', id: 1) }
  let(:sharpness_score) { 85.5 }
  let(:exposure_score) { 0.75 }
  let(:aesthetic_score) { 8 }
  let(:detected_objects) { [{ 'label' => 'cat', 'confidence' => 0.95 }] }

  describe 'interface' do
    it { is_expected.to require(:photo) }
    it { is_expected.to require(:sharpness_score) }
    it { is_expected.to require(:exposure_score) }
    it { is_expected.to require(:aesthetic_score) }
    it { is_expected.to require(:detected_objects) }
    it { is_expected.to returns(:photo_analysis) }
  end

  describe '#call' do
    context 'with valid inputs' do
      it 'is successful' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_success
      end

      it 'creates a PhotoAnalysis record' do
        expect(PhotoAnalysis).to receive(:create!).with(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        ).and_call_original

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
        expect(result.photo_analysis).to be_a(PhotoAnalysis)
      end
    end

    context 'with invalid inputs' do
      it 'fails when photo is not provided' do
        result = described_class.call(
          photo: nil,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Photo is required')
      end

      it 'fails when sharpness_score is not numeric' do
        result = described_class.call(
          photo: photo,
          sharpness_score: 'not_numeric',
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Sharpness score must be numeric')
      end

      it 'fails when exposure_score is not numeric' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: 'not_numeric',
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Exposure score must be numeric')
      end

      it 'fails when aesthetic_score is not numeric' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: 'not_numeric',
          detected_objects: detected_objects
        )
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Aesthetic score must be numeric')
      end

      it 'fails when detected_objects is not an array' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: 'not_an_array'
        )
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Detected objects must be an array')
      end
    end

    context 'when database operation fails' do
      it 'fails when PhotoAnalysis.create! raises a StandardError' do
        expect(PhotoAnalysis).to receive(:create!).and_raise(StandardError, 'Database connection lost')

        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_failure
        expect(result.full_error_message)
          .to eq('Unexpected error while saving photo analysis: Database connection lost')
      end
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
