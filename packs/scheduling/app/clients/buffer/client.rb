# frozen_string_literal: true

require 'faraday'
require 'json'

module Buffer
  # A client for the Buffer API.
  class Client
    # Custom error class for API-specific issues.
    class Error < StandardError; end

    # Base URL for the Buffer API
    BASE_URL = 'https://api.bufferapp.com/1'

    def initialize(access_token: nil)
      @access_token = access_token || Rails.application.credentials.dig(:buffer, :access_token)
      raise ArgumentError, 'Buffer access token is required' if @access_token.blank?
    end

    # Creates a post in Buffer
    #
    # @param image_url [String] The URL of the image to post
    # @param caption [String] The caption for the post
    # @param buffer_profile_id [String] The Buffer profile ID to post to
    # @return [Hash] The response from Buffer containing the post ID
    # @raise [Buffer::Client::Error] if the API returns an error or the request fails
    def create_post(image_url:, caption:, buffer_profile_id:)
      body = build_create_post_body(image_url, caption, buffer_profile_id)
      response = connection.post('/updates/create.json') { |req| req.body = body }

      handle_response(response)
    rescue Faraday::Error => e
      raise Error, "Request failed: #{e.message}"
    end

    # Destroys a post in Buffer
    #
    # @param buffer_post_id [String] The Buffer post ID to destroy
    # @return [Hash] The response from Buffer
    # @raise [Buffer::Client::Error] if the API returns an error or the request fails
    def destroy_post(buffer_post_id:)
      response = connection.post("/updates/#{buffer_post_id}/destroy.json")

      handle_response(response)
    rescue Faraday::Error => e
      raise Error, "Request failed: #{e.message}"
    end

    # Fetches status for posts for a given profile
    #
    # @param buffer_profile_id [String] The Buffer profile ID to fetch posts for
    # @return [Array<Hash>] Array of post statuses from Buffer
    # @raise [Buffer::Client::Error] if the API returns an error or the request fails
    def fetch_status_for_posts(buffer_profile_id:)
      response = connection.get("/profiles/#{buffer_profile_id}/updates/sent.json")

      handle_response(response)
    rescue Faraday::Error => e
      raise Error, "Request failed: #{e.message}"
    end

    private

    def connection
      Faraday.new(url: BASE_URL) do |conn|
        conn.request :json
        conn.response :json
        conn.adapter Faraday.default_adapter
        conn.headers['Authorization'] = "Bearer #{@access_token}"
      end
    end

    def build_create_post_body(image_url, caption, buffer_profile_id)
      {
        text: caption,
        media: { photo: image_url },
        profile_ids: [buffer_profile_id]
      }
    end

    def handle_response(response)
      raise Error, "API Error: #{response.status} - #{response.body}" unless response.success?

      response.body
    end
  end
end
