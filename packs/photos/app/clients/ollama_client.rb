# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'json'
require 'base64'

# A client for the Ollama API.
class OllamaClient
  # Custom error class for API-specific issues.
  class Error < StandardError; end

  # Detects objects in an image using Ollama.
  #
  # @param file_path [String] The absolute path to the image file.
  # @return [Array<Hash>] Array of detected objects with label and confidence.
  # @raise [OllamaClient::Error] if the API returns an error or the request fails.
  def self.detect_objects(file_path:)
    new(file_path: file_path).send(:detect_objects)
  end

  private

  def initialize(file_path:)
    @file_path = file_path
    @base_url = OLLAMA_CONFIG[:url]
  end

  def connection
    Faraday.new(url: @base_url) do |conn|
      conn.request :json
      conn.response :json
      conn.adapter Faraday.default_adapter
    end
  end

  # rubocop:disable Metrics/MethodLength
  def detect_objects
    encoded_image = encode_image
    response = connection.post('/api/generate') do |req|
      req.body = {
        model: 'gemma2:27b',
        prompt: object_detection_prompt,
        images: [encoded_image],
        stream: false,
        format: 'json'
      }
    end

    handle_response(response)
  rescue Faraday::Error => e
    raise Error, "Request failed: #{e.message}"
  end
  # rubocop:enable Metrics/MethodLength

  def encode_image
    Base64.strict_encode64(File.read(@file_path))
  rescue Errno::ENOENT
    raise Error, "Image file not found: #{@file_path}"
  rescue StandardError => e
    raise Error, "Failed to read image file: #{e.message}"
  end

  def object_detection_prompt
    'Analyze this image and identify the main objects present. ' \
      'Return your response as a JSON array where each object has a "label" and "confidence" (0.0-1.0). ' \
      'Focus on the most prominent and recognizable objects. ' \
      'Example format: [{"label": "tree", "confidence": 0.95}, {"label": "car", "confidence": 0.87}]'
  end

  def handle_response(response)
    raise Error, "API Error: #{response.status} - #{response.body}" unless response.success?

    response_body = response.body
    raise Error, 'Empty response from Ollama API' if response_body.blank?

    ollama_response = response_body['response']
    raise Error, 'No response field in Ollama API response' if ollama_response.nil?

    parse_objects_from_response(ollama_response)
  end

  def parse_objects_from_response(response_text)
    # Try to parse the JSON response
    JSON.parse(response_text)
  rescue JSON::ParserError => e
    # If JSON parsing fails, try to extract JSON from the response text
    json_match = response_text.match(/\[.*\]/m)
    raise Error, "No valid JSON array found in response: #{response_text}" unless json_match

    begin
      JSON.parse(json_match[0])
    rescue JSON::ParserError
      raise Error, "Failed to parse JSON response: #{e.message}"
    end
  end
end
