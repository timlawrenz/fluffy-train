# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'spec_helper'

require_relative '../../../../app/commands/photos/analyse/aesthetics'

RSpec.describe Photos::Analyse::Aesthetics, type: :command do
  let(:photo) { double('Photo', path: '/path/to/image.jpg') }

  before do
    allow(OllamaClient).to receive(:analyze_aesthetics).and_return(7.5)
    allow(File).to receive(:exist?).with('/path/to/image.jpg').and_return(true)
  end

  describe '#call' do
    context 'when successful' do
      it 'succeeds' do
        result = described_class.call(photo: photo)
        expect(result).to be_success
      end

      it 'returns the aesthetic score' do
        result = described_class.call(photo: photo)
        expect(result.aesthetic_score).to eq(7.5)
      end
    end

    context 'when photo file does not exist' do
      before do
        allow(File).to receive(:exist?).with('/path/to/image.jpg').and_return(false)
      end

      it 'fails with an error message' do
        result = described_class.call(photo: photo)
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Photo file not found at path: /path/to/image.jpg')
      end
    end

    context 'when OllamaClient raises an error' do
      before do
        error_class = Class.new(StandardError)
        stub_const('OllamaClient::Error', error_class)
        allow(OllamaClient).to receive(:analyze_aesthetics).and_raise(error_class, 'API error')
      end

      it 'fails with an error message' do
        result = described_class.call(photo: photo)
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Failed to analyze image aesthetics: API error')
      end
    end

    context 'when aesthetic score is invalid' do
      before do
        allow(OllamaClient).to receive(:analyze_aesthetics).with(file_path: '/path/to/image.jpg').and_return(11.0)
      end

      it 'fails with validation error' do
        result = described_class.call(photo: photo)
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Invalid aesthetic score: must be a number between 1.0 and 10.0, got 11.0')
      end
    end

    context 'when aesthetic score is below minimum' do
      before do
        allow(OllamaClient).to receive(:analyze_aesthetics).with(file_path: '/path/to/image.jpg').and_return(0.5)
      end

      it 'fails with validation error' do
        result = described_class.call(photo: photo)
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Invalid aesthetic score: must be a number between 1.0 and 10.0, got 0.5')
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow(OllamaClient).to receive(:analyze_aesthetics).and_raise(StandardError, 'Unexpected error')
      end

      it 'fails with an error message' do
        result = described_class.call(photo: photo)
        expect(result).to be_failure
        expect(result.full_error_message).to eq('Unexpected error during aesthetic analysis: Unexpected error')
      end
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles