# frozen_string_literal: true

require 'faraday'
require 'json'

module AI
  class OllamaClient
    DEFAULT_HOST = 'http://localhost:11434'
    DEFAULT_MODEL = 'gemma3:latest'  # Use smaller 4B model instead of 27B
    
    def initialize(host: DEFAULT_HOST, model: DEFAULT_MODEL)
      @host = host
      @model = model
      @connection = Faraday.new(url: @host) do |f|
        f.request :json
        f.response :json
        f.adapter Faraday.default_adapter
      end
    end
    
    def generate(prompt, system: nil, temperature: 0.7, max_tokens: 2000)
      payload = {
        model: @model,
        prompt: prompt,
        stream: false,
        options: {
          temperature: temperature,
          num_predict: max_tokens
        }
      }
      
      payload[:system] = system if system
      
      response = @connection.post('/api/generate', payload.to_json, 'Content-Type' => 'application/json')
      
      if response.success?
        body = response.body.is_a?(String) ? JSON.parse(response.body) : response.body
        body['response']
      else
        raise "Ollama API error: #{response.status} - #{response.body}"
      end
    end
    
    def chat(messages, temperature: 0.7, max_tokens: 2000)
      payload = {
        model: @model,
        messages: messages,
        stream: false,
        options: {
          temperature: temperature,
          num_predict: max_tokens
        }
      }
      
      response = @connection.post('/api/chat', payload.to_json, 'Content-Type' => 'application/json')
      
      if response.success?
        body = response.body.is_a?(String) ? JSON.parse(response.body) : response.body
        body['message']['content']
      else
        raise "Ollama API error: #{response.status} - #{response.body}"
      end
    end
    
    def available?
      response = @connection.get('/api/tags')
      response.success?
    rescue
      false
    end
  end
end
