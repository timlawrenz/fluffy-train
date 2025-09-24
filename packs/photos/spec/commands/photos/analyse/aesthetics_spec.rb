# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'spec_helper'

# Load OllamaClient first since Aesthetics depends on it
require_relative '../../../../app/clients/ollama_client'
require_relative '../../../../app/commands/photos/analyse/aesthetics'

RSpec.describe Photos::Analyse::Aesthetics do
  before do
    stub_const('Photo', Class.new)
  end

  let(:temp_dir) { '/tmp/fluffy_train_aesthetics_test' }
  let(:test_image_path) { File.join(temp_dir, 'test_image.jpg') }
  let(:photo) { double('Photo', path: test_image_path) }

  around do |example|
    FileUtils.mkdir_p(temp_dir)
    create_test_image
    example.run
    FileUtils.rm_rf(temp_dir)
  end

  describe '#call' do
    context 'when OllamaClient successfully returns a score' do
      it 'is successful' do
        allow(OllamaClient).to receive(:get_aesthetic_score).and_return(8)
        result = described_class.call(photo: photo)
        expect(result).to be_success
      end

      it 'returns the aesthetic score' do
        allow(OllamaClient).to receive(:get_aesthetic_score).and_return(7)
        result = described_class.call(photo: photo)
        expect(result.aesthetic_score).to eq(7)
      end

      it 'calls OllamaClient with correct file path' do
        allow(OllamaClient).to receive(:get_aesthetic_score)
          .with(file_path: test_image_path)
          .and_return(6)

        described_class.call(photo: photo)
        expect(OllamaClient).to have_received(:get_aesthetic_score).with(file_path: test_image_path)
      end
    end

    context 'when photo file does not exist' do
      let(:non_existent_photo) { double('Photo', path: '/path/to/non_existent_file.jpg') }

      it 'is a failure' do
        result = described_class.call(photo: non_existent_photo)
        expect(result).to be_failure
      end

      it 'returns an appropriate error message' do
        result = described_class.call(photo: non_existent_photo)
        expect(result.full_error_message).to eq('Photo file not found at path: /path/to/non_existent_file.jpg')
      end

      it 'does not call OllamaClient' do
        expect(OllamaClient).not_to receive(:get_aesthetic_score)
        described_class.call(photo: non_existent_photo)
      end
    end

    context 'when OllamaClient raises an error' do
      it 'is a failure when API connection fails' do
        allow(OllamaClient).to receive(:get_aesthetic_score).and_raise(OllamaClient::Error, 'API connection failed')
        result = described_class.call(photo: photo)
        expect(result).to be_failure
      end

      it 'returns an error message about aesthetic scoring failure' do
        allow(OllamaClient).to receive(:get_aesthetic_score).and_raise(OllamaClient::Error, 'Invalid response format')
        result = described_class.call(photo: photo)
        expect(result.full_error_message).to eq('Failed to get aesthetic score for image: Invalid response format')
      end
    end

    context 'when an unexpected error occurs' do
      it 'is a failure when standard error occurs' do
        allow(OllamaClient).to receive(:get_aesthetic_score).and_raise(StandardError, 'Unexpected error')
        result = described_class.call(photo: photo)
        expect(result).to be_failure
      end

      it 'returns an error message about unexpected error' do
        allow(OllamaClient).to receive(:get_aesthetic_score).and_raise(StandardError, 'Unexpected error')
        result = described_class.call(photo: photo)
        expect(result.full_error_message).to eq('Unexpected error during aesthetic analysis: Unexpected error')
      end
    end
  end

  private

  def create_test_image
    # Create a simple test image file for the tests to use
    File.write(test_image_path, 'fake image content')
  end
end

# rubocop:enable RSpec/VerifiedDoubles
