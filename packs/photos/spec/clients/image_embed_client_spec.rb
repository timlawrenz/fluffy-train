# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageEmbedClient do
  let(:file_path) { Rails.root.join('spec/fixtures/files/test_image.jpg') }
  let(:base_url) { IMAGE_EMBED_CONFIG[:url] }
  let(:endpoint) { "#{base_url}/analyze_image_upload/" }
  let(:embedding_vector) { [0.1] * 512 }

  around do |example|
    # Create a dummy file for upload tests
    FileUtils.mkdir_p(File.dirname(file_path))
    FileUtils.touch(file_path)
    example.run
    FileUtils.rm_f(file_path)
  end

  describe '.generate_embedding' do
    context 'when the request is successful' do
      before do
        stub_request(:post, endpoint)
          .to_return(
            status: 200,
            body: {
              results: {
                whole_image_embedding: {
                  status: 'success',
                  data: embedding_vector,
                  error_message: nil
                }
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the embedding vector' do
        result = described_class.generate_embedding(file_path: file_path)
        expect(result).to eq(embedding_vector)
      end
    end

    context 'when the API returns an error for the operation' do
      before do
        stub_request(:post, endpoint)
          .to_return(
            status: 200,
            body: {
              results: {
                whole_image_embedding: {
                  status: 'error',
                  data: nil,
                  error_message: 'Model not found'
                }
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an ImageEmbedClient::Error' do
        expect { described_class.generate_embedding(file_path: file_path) }
          .to raise_error(ImageEmbedClient::Error, 'Embedding generation failed: Model not found')
      end
    end

    context 'when the HTTP request fails' do
      before do
        stub_request(:post, endpoint).to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises an ImageEmbedClient::Error' do
        expect { described_class.generate_embedding(file_path: file_path) }
          .to raise_error(ImageEmbedClient::Error, 'API Error: 500 - Internal Server Error')
      end
    end

    context 'when there is a connection error' do
      before do
        stub_request(:post, endpoint).to_raise(Faraday::ConnectionFailed.new('Connection refused'))
      end

      it 'raises an ImageEmbedClient::Error' do
        expect { described_class.generate_embedding(file_path: file_path) }
          .to raise_error(ImageEmbedClient::Error, 'Request failed: Connection refused')
      end
    end
  end
end
