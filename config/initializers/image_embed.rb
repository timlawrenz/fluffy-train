# frozen_string_literal: true

path = Rails.root.join('config/image_embed.yml')
config = YAML.load_file(path, aliases: true)
IMAGE_EMBED_CONFIG = config[Rails.env].deep_symbolize_keys
