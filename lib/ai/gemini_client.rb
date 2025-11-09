# frozen_string_literal: true

require 'faraday'
require 'json'
require 'base64'

module AI
  class GeminiClient
    DEFAULT_MODEL = 'gemini-1.5-pro-latest'
    API_BASE = 'https://generativelanguage.googleapis.com/v1beta'
    
    def initialize(api_key: nil, model: DEFAULT_MODEL)
      @api_key = api_key || ENV['GEMINI_API_KEY']
      @model = model
      raise ArgumentError, 'GEMINI_API_KEY environment variable not set' unless @api_key
      
      @connection = Faraday.new(url: API_BASE) do |f|
        f.request :json
        f.response :json
        f.adapter Faraday.default_adapter
      end
    end
    
    def generate(prompt, system: nil, temperature: 0.7, max_tokens: 2000, image_path: nil)
      contents = []
      
      if system
        contents << {
          role: 'user',
          parts: [{ text: system }]
        }
        contents << {
          role: 'model',
          parts: [{ text: 'Understood. I will follow these instructions.' }]
        }
      end
      
      # Build user message parts
      user_parts = []
      
      # Add image if provided
      if image_path && File.exist?(image_path)
        user_parts << build_image_part(image_path)
      end
      
      # Add text prompt
      user_parts << { text: prompt }
      
      contents << {
        role: 'user',
        parts: user_parts
      }
      
      payload = {
        contents: contents,
        generationConfig: {
          temperature: temperature,
          maxOutputTokens: max_tokens
        }
      }
      
      url = "/models/#{@model}:generateContent?key=#{@api_key}"
      response = @connection.post(url, payload.to_json, 'Content-Type' => 'application/json')
      
      if response.success?
        body = response.body.is_a?(String) ? JSON.parse(response.body) : response.body
        body.dig('candidates', 0, 'content', 'parts', 0, 'text')
      else
        raise "Gemini API error: #{response.status} - #{response.body}"
      end
    end
    
    def generate_text(prompt, temperature: 0.7, max_tokens: 2000)
      generate(prompt, temperature: temperature, max_tokens: max_tokens)
    end
    
    def available?
      !@api_key.nil?
    rescue
      false
    end
    
    private
    
    def build_image_part(image_path)
      # Read and encode image
      image_data = File.binread(image_path)
      encoded_image = Base64.strict_encode64(image_data)
      
      # Determine MIME type
      mime_type = case File.extname(image_path).downcase
                  when '.jpg', '.jpeg' then 'image/jpeg'
                  when '.png' then 'image/png'
                  when '.webp' then 'image/webp'
                  when '.heic' then 'image/heic'
                  when '.heif' then 'image/heif'
                  else 'image/jpeg'
                  end
      
      {
        inline_data: {
          mime_type: mime_type,
          data: encoded_image
        }
      }
    end
  end
end
