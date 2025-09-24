# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'spec_helper'
require 'faraday'
require 'json'
require 'base64'
require 'fileutils'

require_relative '../../app/clients/ollama_client'

RSpec.describe OllamaClient do
  let(:temp_dir) { '/tmp/fluffy_train_ollama_test' }
  let(:test_image_path) { File.join(temp_dir, 'test_image.jpg') }
  let(:test_image_content) { 'fake image content' }
  let(:mock_connection) { double('Faraday::Connection') }
  let(:mock_response) { double('Faraday::Response') }

  before do
    stub_const('OLLAMA_CONFIG', { url: 'http://localhost:11434' })
  end

  around do |example|
    FileUtils.mkdir_p(temp_dir)
    File.write(test_image_path, test_image_content)
    example.run
    FileUtils.rm_rf(temp_dir)
  end

  describe '.detect_objects' do
    let(:valid_response_body) do
      {
        'response' => '[{"label": "tree", "confidence": 0.95}, {"label": "car", "confidence": 0.87}]'
      }
    end
    let(:expected_objects) do
      [
        { 'label' => 'tree', 'confidence' => 0.95 },
        { 'label' => 'car', 'confidence' => 0.87 }
      ]
    end

    before do
      allow(Faraday).to receive(:new).and_return(mock_connection)
      allow(mock_connection).to receive(:post).and_return(mock_response)
      allow(mock_response).to receive_messages(success?: true, body: valid_response_body)
    end

    it 'returns detected objects successfully' do
      result = described_class.detect_objects(file_path: test_image_path)
      expect(result).to eq(expected_objects)
    end

    it 'sends correct request to Ollama API' do
      encoded_image = Base64.strict_encode64(test_image_content)
      expected_body = {
        model: 'gemma2:27b',
        prompt: match(/Analyze this image and identify the main objects/),
        images: [encoded_image],
        stream: false,
        format: 'json'
      }

      expect(mock_connection).to receive(:post).with('/api/generate') do |&block|
        request = double('Request')
        allow(request).to receive(:body=)
        expect(request).to receive(:body=).with(expected_body)
        block.call(request)
        mock_response
      end

      described_class.detect_objects(file_path: test_image_path)
    end

    context 'when image file does not exist' do
      it 'raises an error' do
        expect do
          described_class.detect_objects(file_path: '/non/existent/file.jpg')
        end.to raise_error(OllamaClient::Error, /Image file not found/)
      end
    end

    context 'when API returns an error status' do
      before do
        allow(mock_response).to receive_messages(success?: false, status: 500, body: 'Internal Server Error')
      end

      it 'raises an error' do
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /API Error: 500/)
      end
    end

    context 'when API returns empty response' do
      before do
        allow(mock_response).to receive(:body).and_return(nil)
      end

      it 'raises an error' do
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /Empty response from Ollama API/)
      end
    end

    context 'when API response has no response field' do
      before do
        allow(mock_response).to receive(:body).and_return({ 'some_other_field' => 'value' })
      end

      it 'raises an error' do
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /No response field in Ollama API response/)
      end
    end

    context 'when response contains invalid JSON' do
      before do
        allow(mock_response).to receive(:body).and_return({ 'response' => 'invalid json' })
      end

      it 'raises an error' do
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /No valid JSON array found in response/)
      end
    end

    context 'when response contains JSON but not as the whole response' do
      before do
        response_text = 'Some text before [{"label": "tree", "confidence": 0.95}] some text after'
        allow(mock_response).to receive(:body).and_return({ 'response' => response_text })
      end

      it 'extracts and parses the JSON array' do
        result = described_class.detect_objects(file_path: test_image_path)
        expect(result).to eq([{ 'label' => 'tree', 'confidence' => 0.95 }])
      end
    end

    context 'when JSON extraction also fails' do
      before do
        response_text = 'Some text with malformed JSON [{"label": "tree", "confidence":}] text'
        allow(mock_response).to receive(:body).and_return({ 'response' => response_text })
      end

      it 'raises an error' do
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /Failed to parse JSON response/)
      end
    end

    context 'when network request fails' do
      before do
        allow(mock_connection).to receive(:post).and_raise(Faraday::ConnectionFailed, 'Connection failed')
      end

      it 'raises an error' do
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /Request failed: Connection failed/)
      end
    end

    context 'when file reading fails with permission error' do
      before do
        allow(File).to receive(:read).with(test_image_path).and_raise(Errno::EACCES, 'Permission denied')
      end

      it 'raises an error' do
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /Failed to read image file/)
      end
    end
  end

  describe 'configuration' do
    it 'uses the configured Ollama URL' do
      allow(Faraday).to receive(:new).with(url: 'http://localhost:11434').and_return(mock_connection)
      allow(mock_connection).to receive(:post).and_return(mock_response)
      allow(mock_response).to receive_messages(success?: true, body: { 'response' => '[]' })

      described_class.detect_objects(file_path: test_image_path)

      expect(Faraday).to have_received(:new).with(url: 'http://localhost:11434')
    end
  end

  describe 'prompt generation' do
    it 'includes instructions for JSON format and object detection' do
      client = described_class.new(file_path: test_image_path)
      prompt = client.send(:object_detection_prompt)

      expect(prompt).to include('JSON array')
      expect(prompt).to include('label')
      expect(prompt).to include('confidence')
      expect(prompt).to include('0.0-1.0')
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
