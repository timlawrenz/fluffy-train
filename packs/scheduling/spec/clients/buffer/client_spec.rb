# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Buffer::Client do
  let(:access_token) { 'test_buffer_token' }
  let(:client) { described_class.new(access_token: access_token) }
  let(:base_url) { described_class::BASE_URL }

  describe '#initialize' do
    context 'when access_token is provided' do
      it 'initializes with the provided token' do
        expect { client }.not_to raise_error
      end
    end

    context 'when access_token is not provided' do
      before do
        allow(Rails.application.credentials).to receive(:dig).with(:buffer, :access_token).and_return('rails_token')
      end

      it 'uses the token from Rails credentials' do
        expect { described_class.new }.not_to raise_error
      end
    end

    context 'when no access_token is available' do
      before do
        allow(Rails.application.credentials).to receive(:dig).with(:buffer, :access_token).and_return(nil)
      end

      it 'raises an ArgumentError' do
        expect { described_class.new }.to raise_error(ArgumentError, 'Buffer access token is required')
      end
    end
  end

  describe '#create_post' do
    let(:image_url) { 'https://example.com/image.jpg' }
    let(:caption) { 'Test caption' }
    let(:buffer_profile_id) { 'profile123' }
    let(:endpoint) { "#{base_url}/updates/create.json" }

    context 'when the request is successful' do
      let(:successful_response) do
        {
          'success' => true,
          'updates' => [
            {
              'id' => 'update123',
              'status' => 'buffer',
              'text' => caption
            }
          ]
        }
      end

      before do
        stub_request(:post, endpoint)
          .with(
            body: {
              text: caption,
              media: { photo: image_url },
              profile_ids: [buffer_profile_id]
            },
            headers: {
              'Authorization' => "Bearer #{access_token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: successful_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'creates a post and returns the response' do
        result = client.create_post(
          image_url: image_url,
          caption: caption,
          buffer_profile_id: buffer_profile_id
        )
        expect(result).to eq(successful_response)
      end
    end

    context 'when the HTTP request fails' do
      before do
        stub_request(:post, endpoint).to_return(status: 400, body: 'Bad Request')
      end

      it 'raises a Buffer::Client::Error' do
        expect do
          client.create_post(
            image_url: image_url,
            caption: caption,
            buffer_profile_id: buffer_profile_id
          )
        end.to raise_error(Buffer::Client::Error, 'API Error: 400 - Bad Request')
      end
    end

    context 'when there is a connection error' do
      before do
        stub_request(:post, endpoint).to_raise(Faraday::ConnectionFailed.new('Connection refused'))
      end

      it 'raises a Buffer::Client::Error' do
        expect do
          client.create_post(
            image_url: image_url,
            caption: caption,
            buffer_profile_id: buffer_profile_id
          )
        end.to raise_error(Buffer::Client::Error, 'Request failed: Connection refused')
      end
    end
  end

  describe '#destroy_post' do
    let(:buffer_post_id) { 'update123' }
    let(:endpoint) { "#{base_url}/updates/#{buffer_post_id}/destroy.json" }

    context 'when the request is successful' do
      let(:successful_response) do
        {
          'success' => true,
          'message' => 'Update successfully destroyed'
        }
      end

      before do
        stub_request(:post, endpoint)
          .with(
            headers: {
              'Authorization' => "Bearer #{access_token}"
            }
          )
          .to_return(
            status: 200,
            body: successful_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'destroys the post and returns the response' do
        result = client.destroy_post(buffer_post_id: buffer_post_id)
        expect(result).to eq(successful_response)
      end
    end

    context 'when the HTTP request fails' do
      before do
        stub_request(:post, endpoint).to_return(status: 404, body: 'Not Found')
      end

      it 'raises a Buffer::Client::Error' do
        expect do
          client.destroy_post(buffer_post_id: buffer_post_id)
        end.to raise_error(Buffer::Client::Error, 'API Error: 404 - Not Found')
      end
    end

    context 'when there is a connection error' do
      before do
        stub_request(:post, endpoint).to_raise(Faraday::ConnectionFailed.new('Connection refused'))
      end

      it 'raises a Buffer::Client::Error' do
        expect do
          client.destroy_post(buffer_post_id: buffer_post_id)
        end.to raise_error(Buffer::Client::Error, 'Request failed: Connection refused')
      end
    end
  end

  describe '#fetch_status_for_posts' do
    let(:buffer_profile_id) { 'profile123' }
    let(:endpoint) { "#{base_url}/profiles/#{buffer_profile_id}/updates/sent.json" }

    context 'when the request is successful' do
      let(:successful_response) do
        {
          'total' => 2,
          'updates' => [
            {
              'id' => 'update123',
              'status' => 'sent',
              'text' => 'First post',
              'sent_at' => 1_632_145_200
            },
            {
              'id' => 'update456',
              'status' => 'failed',
              'text' => 'Second post',
              'sent_at' => nil
            }
          ]
        }
      end

      before do
        stub_request(:get, endpoint)
          .with(
            headers: {
              'Authorization' => "Bearer #{access_token}"
            }
          )
          .to_return(
            status: 200,
            body: successful_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fetches the post statuses and returns the response' do
        result = client.fetch_status_for_posts(buffer_profile_id: buffer_profile_id)
        expect(result).to eq(successful_response)
      end
    end

    context 'when the HTTP request fails' do
      before do
        stub_request(:get, endpoint).to_return(status: 403, body: 'Forbidden')
      end

      it 'raises a Buffer::Client::Error' do
        expect do
          client.fetch_status_for_posts(buffer_profile_id: buffer_profile_id)
        end.to raise_error(Buffer::Client::Error, 'API Error: 403 - Forbidden')
      end
    end

    context 'when there is a connection error' do
      before do
        stub_request(:get, endpoint).to_raise(Faraday::ConnectionFailed.new('Connection refused'))
      end

      it 'raises a Buffer::Client::Error' do
        expect do
          client.fetch_status_for_posts(buffer_profile_id: buffer_profile_id)
        end.to raise_error(Buffer::Client::Error, 'Request failed: Connection refused')
      end
    end
  end
end
