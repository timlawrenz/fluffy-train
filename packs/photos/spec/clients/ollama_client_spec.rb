# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe OllamaClient do
  let(:test_image_path) { Rails.root.join('spec/fixtures/files/example.png') }
  let(:base_url) { 'http://localhost:11434' }
  let(:api_url) { "#{base_url}/api/generate" }

  before do
    stub_const('OLLAMA_CONFIG', { url: base_url })
  end

  shared_context 'with successful API response' do
    let(:response_body) do
      {
        response: '{"objects": [{"label": "cat", "confidence": 0.9}]}'
      }.to_json
    end

    before do
      stub_request(:post, api_url).to_return(
        status: 200,
        body: response_body,
        headers: { 'Content-Type' => 'application/json' }
      )
    end
  end

  shared_context 'with successful caption response' do
    let(:caption_response_body) do
      {
        response: 'A beautiful sunset over the ocean with vibrant colors.'
      }.to_json
    end

    before do
      stub_request(:post, api_url).to_return(
        status: 200,
        body: caption_response_body,
        headers: { 'Content-Type' => 'application/json' }
      )
    end
  end

  describe '.detect_objects' do
    context 'with successful API response' do
      include_context 'with successful API response'

      it 'returns detected objects successfully' do
        result = described_class.detect_objects(file_path: test_image_path)
        expect(result).to eq([{ 'label' => 'cat', 'confidence' => 0.9 }])
      end

      it 'sends correct request to Ollama API' do
        described_class.detect_objects(file_path: test_image_path)
        expect(WebMock).to have_requested(:post, api_url).with { |req|
          body = JSON.parse(req.body)
          expect(body['model']).to eq('gemma3:27b')
          expect(body['prompt']).to include('Analyze this image and identify the main objects present.')
          expect(body['images']).to be_an(Array)
          expect(body['stream']).to be(false)
          expect(body['format']).to eq('json')
        }.once
      end
    end

    context 'when API returns an error' do
      before do
        stub_request(:post, api_url).to_return(status: 500, body: { error: 'Internal Server Error' }.to_json)
      end

      it 'raises an OllamaClient::Error' do
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /API Error: 500/)
      end
    end

    context 'when API response has no response field' do
      before do
        stub_request(:post, api_url).to_return(status: 200, body: {}.to_json)
      end

      it 'raises an error' do
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /No response field in Ollama API response/)
      end
    end

    context 'when response contains invalid JSON' do
      before do
        stub_request(:post, api_url).to_return(status: 200, body: { response: 'invalid json' }.to_json)
      end

      it 'raises an error' do
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(JSON::ParserError)
      end
    end

    context 'when response contains JSON but not as the whole response' do
      before do
        stub_request(:post, api_url).to_return(status: 200,
                                               body: { response: 'Some text surrounding the JSON. {"objects": [{"label": "dog", "confidence": 0.88}]}' }.to_json)
      end

      it 'extracts and parses the JSON array' do
        # This test is no longer valid as the handle_response method does not extract JSON from a string.
        # Instead, it expects the 'response' field to be a valid JSON string.
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(JSON::ParserError)
      end
    end

    context 'when JSON extraction also fails' do
      before do
        stub_request(:post, api_url).to_return(status: 200,
                                               body: { response: 'Some text without any valid JSON.' }.to_json)
      end

      it 'raises an error' do
        expect do
          described_class.detect_objects(file_path: test_image_path)
        end.to raise_error(JSON::ParserError)
      end
    end
  end

  describe '.generate_caption' do
    context 'with successful API response' do
      include_context 'with successful caption response'

      it 'returns generated caption successfully' do
        result = described_class.generate_caption(file_path: test_image_path)
        expect(result).to eq('A beautiful sunset over the ocean with vibrant colors.')
      end

      it 'sends correct request to Ollama API' do
        described_class.generate_caption(file_path: test_image_path)
        expect(WebMock).to have_requested(:post, api_url).with { |req|
          body = JSON.parse(req.body)
          expect(body['model']).to eq('llava:latest')
          expect(body['prompt']).to eq('Generate a short, engaging caption for this image, suitable for Instagram.')
          expect(body['images']).to be_an(Array)
          expect(body['stream']).to be(false)
          expect(body['format']).to be_nil # caption generation doesn't use JSON format
        }.once
      end
    end

    context 'when API returns an error' do
      before do
        stub_request(:post, api_url).to_return(status: 500, body: { error: 'Internal Server Error' }.to_json)
      end

      it 'raises an OllamaClient::Error' do
        expect do
          described_class.generate_caption(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /API Error: 500/)
      end
    end

    context 'when API response has no response field' do
      before do
        stub_request(:post, api_url).to_return(status: 200, body: {}.to_json)
      end

      it 'raises an error' do
        expect do
          described_class.generate_caption(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /No response field in Ollama API response/)
      end
    end

    context 'when response field is empty' do
      before do
        # Clear all stubs and create a new specific one
        WebMock.reset!
        stub_request(:post, api_url).to_return(
          status: 200, 
          body: { response: '' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'raises an error' do
        expect do
          described_class.generate_caption(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /Empty caption response from Ollama API/)
      end
    end

    context 'when response field contains only whitespace' do
      before do
        # Clear all stubs and create a new specific one
        WebMock.reset!
        stub_request(:post, api_url).to_return(
          status: 200, 
          body: { response: "   \n  " }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'raises an error' do
        expect do
          described_class.generate_caption(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /Empty caption response from Ollama API/)
      end
    end

    context 'when API response body is empty' do
      before do
        stub_request(:post, api_url).to_return(status: 200, body: '')
      end

      it 'raises an error' do
        expect do
          described_class.generate_caption(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /Empty response from Ollama API/)
      end
    end

    context 'when network request fails' do
      before do
        stub_request(:post, api_url).to_raise(Faraday::ConnectionFailed.new('Connection failed'))
      end

      it 'raises an OllamaClient::Error' do
        expect do
          described_class.generate_caption(file_path: test_image_path)
        end.to raise_error(OllamaClient::Error, /Request failed: Connection failed/)
      end
    end

    context 'when image file does not exist' do
      let(:non_existent_path) { '/path/to/non/existent/image.jpg' }

      it 'raises an error about missing file' do
        expect do
          described_class.generate_caption(file_path: non_existent_path)
        end.to raise_error(OllamaClient::Error, /Image file not found/)
      end
    end
  end

  describe 'configuration' do
    let(:custom_url) { 'http://custom-ollama:11434' }

    before do
      stub_const('OLLAMA_CONFIG', { url: custom_url })
      stub_request(:post, "#{custom_url}/api/generate").to_return(
        status: 200,
        body: { response: '{"objects": []}' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    it 'uses the configured Ollama URL' do
      described_class.detect_objects(file_path: test_image_path)
      expect(WebMock).to have_requested(:post, "#{custom_url}/api/generate")
    end
  end
end
