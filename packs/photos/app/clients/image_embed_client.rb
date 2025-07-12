# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'json'

# A client for the image_embed service.
class ImageEmbedClient
  # Custom error class for API-specific issues.
  class Error < StandardError; end

  # Fetches an embedding for a given image file path.
  #
  # @param file_path [String] The absolute path to the image file.
  # @return [Array<Float>] The embedding vector.
  # @raise [ImageEmbedClient::Error] if the API returns an error or the request fails.
  def self.generate_embedding(file_path:)
    new(file_path: file_path).send(:generate_embedding)
  end

  private

  def initialize(file_path:)
    @file_path = file_path
    @base_url = IMAGE_EMBED_CONFIG[:url]
  end

  def connection
    Faraday.new(url: @base_url) do |conn|
      conn.request :multipart
      conn.request :url_encoded
      conn.adapter Faraday.default_adapter
    end
  end

  def generate_embedding
    response = connection.post('/analyze_image_upload/') do |req|
      req.body = {
        image_file: Faraday::Multipart::FilePart.new(@file_path.to_s, 'image/jpeg'),
        tasks_json: tasks_payload
      }
    end

    handle_response(response)
  rescue Faraday::Error => e
    raise Error, "Request failed: #{e.message}"
  end

  def tasks_payload
    tasks = [
      {
        operation_id: 'whole_image_embedding',
        type: 'embed_clip_vit_b_32',
        params: { target: 'whole_image' }
      }
    ]
    JSON.generate(tasks)
  end

  def handle_response(response)
    unless response.success?
      raise Error, "API Error: #{response.status} - #{response.body}"
    end

    body = JSON.parse(response.body)
    result = body.dig('results', 'whole_image_embedding')

    if result['status'] == 'success'
      result['data']
    else
      raise Error, "Embedding generation failed: #{result['error_message']}"
    end
  end
end
