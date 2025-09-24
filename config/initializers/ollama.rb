# frozen_string_literal: true

# Configuration for Ollama API
OLLAMA_CONFIG = {
  url: ENV.fetch('OLLAMA_URL', 'http://localhost:11434')
}.freeze
