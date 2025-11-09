# frozen_string_literal: true

require 'faraday'
require 'json'

module AI
  class GeminiClient
    DEFAULT_MODEL = 'gemini-2.0-flash-exp'
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
    
    def generate(prompt, system: nil, temperature: 0.7, max_tokens: 2000)
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
      
      contents << {
        role: 'user',
        parts: [{ text: prompt }]
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
    
    def available?
      !@api_key.nil?
    rescue
      false
    end
  end
end
