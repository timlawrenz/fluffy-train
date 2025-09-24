# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'spec_helper'

# Load OllamaClient first since ObjectDetection depends on it
require_relative '../../../../app/clients/ollama_client'
require_relative '../../../../app/commands/photos/analyse/object_detection'

RSpec.describe Photos::Analyse::ObjectDetection do
  before do
    stub_const('Photo', Class.new)
  end

  let(:temp_dir) { '/tmp/fluffy_train_object_detection_test' }
  let(:test_image_path) { File.join(temp_dir, 'test_image.jpg') }
  let(:photo) { double('Photo', path: test_image_path) }
  let(:valid_objects_response) do
    [
      { 'label' => 'tree', 'confidence' => 0.95 },
      { 'label' => 'car', 'confidence' => 0.87 }
    ]
  end

  around do |example|
    FileUtils.mkdir_p(temp_dir)
    create_test_image
    example.run
    FileUtils.rm_rf(temp_dir)
  end

  describe '#call' do
    context 'when OllamaClient successfully detects objects' do
      it 'is successful' do
        allow(OllamaClient).to receive(:detect_objects).and_return(valid_objects_response)
        result = described_class.call(photo: photo)
        expect(result).to be_success
      end

      it 'returns the detected objects' do
        allow(OllamaClient).to receive(:detect_objects).and_return(valid_objects_response)
        result = described_class.call(photo: photo)
        expect(result.detected_objects).to eq(valid_objects_response)
      end

      it 'calls OllamaClient with correct file path' do
        allow(OllamaClient).to receive(:detect_objects)
          .with(file_path: test_image_path)
          .and_return(valid_objects_response)
        described_class.call(photo: photo)
        expect(OllamaClient).to have_received(:detect_objects).with(file_path: test_image_path)
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
        expect(OllamaClient).not_to receive(:detect_objects)
        described_class.call(photo: non_existent_photo)
      end
    end

    context 'when OllamaClient raises an error' do
      it 'is a failure when API connection fails' do
        allow(OllamaClient).to receive(:detect_objects).and_raise(OllamaClient::Error, 'API connection failed')
        result = described_class.call(photo: photo)
        expect(result).to be_failure
      end

      it 'returns an error message about object detection failure' do
        allow(OllamaClient).to receive(:detect_objects).and_raise(OllamaClient::Error, 'API connection failed')
        result = described_class.call(photo: photo)
        expect(result.full_error_message).to eq('Failed to detect objects in image: API connection failed')
      end
    end

    context 'when an unexpected error occurs' do
      it 'is a failure when standard error occurs' do
        allow(OllamaClient).to receive(:detect_objects).and_raise(StandardError, 'Unexpected error')
        result = described_class.call(photo: photo)
        expect(result).to be_failure
      end

      it 'returns an error message about unexpected error' do
        allow(OllamaClient).to receive(:detect_objects).and_raise(StandardError, 'Unexpected error')
        result = described_class.call(photo: photo)
        expect(result.full_error_message).to eq('Unexpected error during object detection: Unexpected error')
      end
    end

    context 'when OllamaClient returns invalid responses' do
      context 'when response is not an array' do
        it 'is a failure' do
          allow(OllamaClient).to receive(:detect_objects).and_return('not an array')
          result = described_class.call(photo: photo)
          expect(result).to be_failure
        end

        it 'returns an error message about invalid format' do
          allow(OllamaClient).to receive(:detect_objects).and_return('not an array')
          result = described_class.call(photo: photo)
          expect(result.full_error_message).to match(/Invalid response format: expected array but got String/)
        end
      end

      context 'when array contains non-hash objects' do
        it 'is a failure' do
          allow(OllamaClient).to receive(:detect_objects).and_return(['not a hash'])
          result = described_class.call(photo: photo)
          expect(result).to be_failure
        end

        it 'returns an error message about invalid object type' do
          allow(OllamaClient).to receive(:detect_objects).and_return(['not a hash'])
          result = described_class.call(photo: photo)
          expect(result.full_error_message).to match(/Invalid object at index 0: expected hash but got String/)
        end
      end

      context 'when object is missing required keys' do
        it 'is a failure' do
          allow(OllamaClient).to receive(:detect_objects).and_return([{ 'only_label' => 'tree' }])
          result = described_class.call(photo: photo)
          expect(result).to be_failure
        end

        it 'returns an error message about missing keys' do
          allow(OllamaClient).to receive(:detect_objects).and_return([{ 'only_label' => 'tree' }])
          result = described_class.call(photo: photo)
          expect(result.full_error_message).to match(/missing required keys 'label' or 'confidence'/)
        end
      end

      context 'when confidence value is invalid' do
        it 'is a failure' do
          allow(OllamaClient).to receive(:detect_objects).and_return([{ 'label' => 'tree', 'confidence' => 1.5 }])
          result = described_class.call(photo: photo)
          expect(result).to be_failure
        end

        it 'returns an error message about invalid confidence' do
          allow(OllamaClient).to receive(:detect_objects).and_return([{ 'label' => 'tree', 'confidence' => 1.5 }])
          result = described_class.call(photo: photo)
          expect(result.full_error_message).to match(/Invalid confidence value.*must be a number between 0.0 and 1.0/)
        end
      end

      context 'when label is invalid' do
        it 'is a failure' do
          allow(OllamaClient).to receive(:detect_objects).and_return([{ 'label' => '', 'confidence' => 0.9 }])
          result = described_class.call(photo: photo)
          expect(result).to be_failure
        end

        it 'returns an error message about invalid label' do
          allow(OllamaClient).to receive(:detect_objects).and_return([{ 'label' => '', 'confidence' => 0.9 }])
          result = described_class.call(photo: photo)
          expect(result.full_error_message).to match(/Invalid label.*must be a non-empty string/)
        end
      end

      context 'with mixed valid and invalid objects' do
        let(:invalid_objects) do
          [
            { 'label' => 'valid_object', 'confidence' => 0.8 },
            { 'label' => '', 'confidence' => 0.9 } # Invalid: empty label
          ]
        end

        it 'is a failure' do
          allow(OllamaClient).to receive(:detect_objects).and_return(invalid_objects)
          result = described_class.call(photo: photo)
          expect(result).to be_failure
        end

        it 'returns an error message about the first invalid object' do
          allow(OllamaClient).to receive(:detect_objects).and_return(invalid_objects)
          result = described_class.call(photo: photo)
          expect(result.full_error_message).to match(/Invalid label at index 1/)
        end
      end
    end

    context 'with edge cases' do
      context 'when response is an empty array' do
        it 'is successful with empty response' do
          allow(OllamaClient).to receive(:detect_objects).and_return([])
          result = described_class.call(photo: photo)
          expect(result).to be_success
        end

        it 'returns empty array' do
          allow(OllamaClient).to receive(:detect_objects).and_return([])
          result = described_class.call(photo: photo)
          expect(result.detected_objects).to eq([])
        end
      end

      context 'with confidence values at boundaries' do
        let(:boundary_objects) do
          [
            { 'label' => 'min_confidence', 'confidence' => 0.0 },
            { 'label' => 'max_confidence', 'confidence' => 1.0 }
          ]
        end

        it 'is successful with boundary confidence values' do
          allow(OllamaClient).to receive(:detect_objects).and_return(boundary_objects)
          result = described_class.call(photo: photo)
          expect(result).to be_success
        end

        it 'accepts confidence values at boundaries' do
          allow(OllamaClient).to receive(:detect_objects).and_return(boundary_objects)
          result = described_class.call(photo: photo)
          expect(result.detected_objects).to eq(boundary_objects)
        end
      end
    end
  end

  private

  def create_test_image
    # Create a simple test image file (just empty for testing purposes)
    File.write(test_image_path, 'fake image content')
  end
end

# rubocop:enable RSpec/VerifiedDoubles
