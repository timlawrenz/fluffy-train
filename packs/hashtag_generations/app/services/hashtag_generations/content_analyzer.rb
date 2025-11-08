# frozen_string_literal: true

module HashtagGenerations
  # Analyzes photo content and generates relevant hashtags
  class ContentAnalyzer
    def self.extract_tags(photo)
      new(photo).extract_tags
    end

    def initialize(photo)
      @photo = photo
    end

    def extract_tags
      tags = []
      
      # Extract from detected objects
      tags.concat(object_based_tags)
      
      # Extract from existing photo analysis tags
      tags.concat(analysis_tags)
      
      tags.uniq
    end

    private

    def object_based_tags
      return [] unless @photo.photo_analysis&.detected_objects
      
      detected_objects = parse_detected_objects
      ObjectMapper.map_objects(detected_objects)
    end

    def parse_detected_objects
      objects = @photo.photo_analysis.detected_objects
      
      case objects
      when String
        # Parse JSON string if stored as string
        JSON.parse(objects)
      when Array
        objects
      else
        []
      end
    rescue JSON::ParserError
      []
    end

    def analysis_tags
      return [] unless @photo.photo_analysis&.respond_to?(:tags)
      return [] unless @photo.photo_analysis.tags.present?
      
      # Format existing tags as hashtags
      @photo.photo_analysis.tags.map do |tag|
        format_as_hashtag(tag)
      end
    end

    def format_as_hashtag(tag)
      cleaned = tag.to_s.gsub(/[^a-zA-Z0-9]/, '')
      cleaned.start_with?('#') ? cleaned : "##{cleaned}"
    end
  end
end
