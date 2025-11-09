# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'json'
require 'base64'

# A client for the Ollama API.
# rubocop:disable Metrics/ClassLength
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

  # Gets an aesthetic score for an image using Ollama.
  #
  # @param file_path [String] The absolute path to the image file.
  # @return [Integer] Aesthetic score from 1 to 10.
  # @raise [OllamaClient::Error] if the API returns an error or the request fails.
  def self.get_aesthetic_score(file_path:)
    new(file_path: file_path).send(:aesthetic_score)
  end

  # Generates a caption for an image using Ollama.
  #
  # @param file_path [String] The absolute path to the image file.
  # @return [String] Generated caption suitable for Instagram.
  # @raise [OllamaClient::Error] if the API returns an error or the request fails.
  def self.generate_caption(file_path:)
    new(file_path: file_path).send(:generate_caption)
  end

  # Generates a caption with custom prompts for persona-specific voice.
  #
  # @param file_path [String] The absolute path to the image file.
  # @param system_prompt [String] System instructions for caption generation.
  # @param user_prompt [String] User prompt with context.
  # @return [String] Generated caption matching persona voice.
  # @raise [OllamaClient::Error] if the API returns an error or the request fails.
  def self.generate_caption_with_prompt(file_path:, system_prompt:, user_prompt:)
    new(file_path: file_path).send(:generate_caption_with_custom_prompt, system_prompt, user_prompt)
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
        model: 'gemma3:27b',
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

  def aesthetic_score
    encoded_image = encode_image
    response = connection.post('/api/generate') do |req|
      req.body = {
        model: 'gemma3:27b',
        prompt: aesthetic_score_prompt,
        images: [encoded_image],
        stream: false
      }
    end

    handle_aesthetic_response(response)
  rescue Faraday::Error => e
    raise Error, "Request failed: #{e.message}"
  end

  def generate_caption
    encoded_image = encode_image
    response = connection.post('/api/generate') do |req|
      req.body = {
        model: 'gemma3:27b',
        prompt: caption_generation_prompt,
        images: [encoded_image],
        stream: false
      }
    end

    handle_caption_response(response)
  rescue Faraday::Error => e
    raise Error, "Request failed: #{e.message}"
  end

  def generate_caption_with_custom_prompt(system_prompt, user_prompt)
    encoded_image = encode_image
    combined_prompt = "#{system_prompt}\n\n#{user_prompt}"
    
    response = connection.post('/api/generate') do |req|
      req.body = {
        model: 'gemma3:27b',
        prompt: combined_prompt,
        images: [encoded_image],
        stream: false
      }
    end

    handle_caption_response(response)
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

  def aesthetic_score_prompt
    'Analyze this image and provide a subjective aesthetic score from 1 to 10, ' \
      'where 1 is poor aesthetic quality and 10 is excellent aesthetic quality. ' \
      'Consider factors like composition, lighting, color harmony, visual balance, and overall appeal. ' \
      'Respond with only a single number between 1 and 10.'
  end

  def caption_generation_prompt
    'Generate a short, engaging caption for this image, suitable for Instagram.'
  end

  def handle_response(response)
    raise Error, "API Error: #{response.status} - #{response.body}" unless response.success?

    response_body = response.body
    ollama_response = response_body['response']
    raise Error, 'No response field in Ollama API response' if ollama_response.nil?
    raise Error, 'Empty response from Ollama API' if ollama_response.blank?

    JSON.parse(ollama_response)['objects']
  end

  def handle_aesthetic_response(response)
    raise Error, "API Error: #{response.status} - #{response.body}" unless response.success?

    response_body = response.body
    raise Error, 'Empty response from Ollama API' if response_body.blank?

    ollama_response = response_body['response']
    raise Error, 'No response field in Ollama API response' if ollama_response.nil?

    parse_aesthetic_score_from_response(ollama_response)
  end

  def handle_caption_response(response)
    raise Error, "API Error: #{response.status} - #{response.body}" unless response.success?

    response_body = response.body
    raise Error, 'Empty response from Ollama API' if response_body.blank?

    ollama_response = response_body['response']
    raise Error, 'No response field in Ollama API response' if ollama_response.nil?

    # Check if response is empty or contains only whitespace
    raise Error, 'Empty caption response from Ollama API' if ollama_response.blank? || ollama_response.strip.empty?

    ollama_response.strip
  end

  def parse_aesthetic_score_from_response(response_text)
    # Extract numeric score from response text
    # Handle various possible formats like "8", "Score: 7", "The aesthetic score is 6", etc.
    numbers = response_text.scan(/\b\d+\b/).map(&:to_i)

    # Find the first number that's in the valid range 1-10
    valid_score = numbers.find { |num| num.between?(1, 10) }

    raise Error, "No valid score (1-10) found in response: #{response_text}" unless valid_score

    valid_score
  end
end
# rubocop:enable Metrics/ClassLength
