# frozen_string_literal: true

require 'faraday'
require 'json'

module Instagram
  # A client for the Instagram Graph API.
  class Client
    # Custom error class for API-specific issues.
    class Error < StandardError; end

    # Base URL for the Instagram Graph API
    BASE_URL = 'https://graph.facebook.com/v20.0'

    def initialize
      @app_id = Rails.application.credentials.dig(:instagram, :app_id)
      @app_secret = Rails.application.credentials.dig(:instagram, :app_secret)
      @access_token = Rails.application.credentials.dig(:instagram, :access_token)
      @account_id = Rails.application.credentials.dig(:instagram, :account_id)

      raise ArgumentError, 'Instagram credentials are required' if [@app_id, @app_secret, @access_token,
                                                                    @account_id].any?(&:blank?)
    end

    # Creates a post in Instagram
    #
    # @param image_url [String] The publicly accessible URL of the image to post
    # @param caption [String] The caption for the post
    # @return [Hash] The response from Instagram containing the post ID
    # @raise [Instagram::Client::Error] if the API returns an error or the request fails
    def create_post(image_url:, caption:)
      # Step 1: Create a media container
      creation_id = create_media_container(image_url, caption)

      # Step 2: Publish the media container
      publish_media_container(creation_id)
    rescue Faraday::Error => e
      raise Error, "Request failed: #{e.message}"
    end

    # Destroys a post in Instagram
    #
    # @param post_id [String] The Instagram post ID to destroy
    # @return [Hash] The response from Instagram
    # @raise [Instagram::Client::Error] if the API returns an error or the request fails
    def destroy_post(post_id:)
      # NOTE: The Instagram Graph API does not support deleting posts.
      # This method could be used to hide or archive a post if that functionality is available.
      raise NotImplementedError, 'The Instagram Graph API does not support deleting posts.'
    end

    # Fetches status for posts for a given profile
    #
    # @return [Array<Hash>] Array of post statuses from Instagram
    # @raise [Instagram::Client::Error] if the API returns an error or the request fails
    def fetch_status_for_posts
      # TODO: Implement fetching recent posts from the Instagram API.
      # This will involve a GET request to /{ig-user-id}/media.
      raise NotImplementedError, 'fetch_status_for_posts is not yet implemented'
    end

    private

    def connection
      Faraday.new(url: BASE_URL) do |conn|
        conn.request :url_encoded
        conn.response :json
        conn.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      raise Error, "API Error: #{response.status} - #{response.body}" unless response.success?

      response.body
    end

    def create_media_container(image_url, caption)
      response = connection.post("#{@account_id}/media") do |req|
        req.params['image_url'] = image_url
        req.params['caption'] = caption
        req.params['access_token'] = @access_token
      end
      handle_response(response)['id']
    end

    def publish_media_container(creation_id)
      response = connection.post("#{@account_id}/media_publish") do |req|
        req.params['creation_id'] = creation_id
        req.params['access_token'] = @access_token
      end
      handle_response(response)
    end
  end
end
