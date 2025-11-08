# frozen_string_literal: true

module CaptionGenerations
  class TemplateGenerator
    TEMPLATES = {
      default: [
        "Capturing moments 📸",
        "A glimpse into my world ✨",
        "Living in the moment",
        "Today's vibe",
        "Feeling inspired"
      ],
      nature: [
        "Nature's beauty never disappoints 🌿",
        "Finding peace in the outdoors",
        "Earth's artwork",
        "Natural vibes"
      ],
      urban: [
        "City life 🏙️",
        "Urban exploration",
        "Concrete jungle adventures",
        "Street scenes"
      ],
      coffee: [
        "Coffee time ☕",
        "Fueled by caffeine",
        "Morning ritual",
        "But first, coffee"
      ]
    }.freeze

    def self.generate(cluster: nil, config: nil)
      new(cluster: cluster, config: config).generate
    end

    def initialize(cluster: nil, config: nil)
      @cluster = cluster
      @config = config
    end

    def generate
      templates = select_templates
      caption = templates.sample

      adjust_for_tone(caption)
    end

    private

    def select_templates
      cluster_key = detect_cluster_category
      TEMPLATES[cluster_key] || TEMPLATES[:default]
    end

    def detect_cluster_category
      return :default unless @cluster&.name

      cluster_name = @cluster.name.downcase
      return :nature if cluster_name.include?('nature') || cluster_name.include?('outdoor')
      return :urban if cluster_name.include?('urban') || cluster_name.include?('city')
      return :coffee if cluster_name.include?('coffee') || cluster_name.include?('cafe')

      :default
    end

    def adjust_for_tone(caption)
      return caption unless @config

      caption = caption.gsub(/[📸✨🌿🏙️☕]/, '') unless @config.style[:use_emoji]
      caption.strip
    end
  end
end
