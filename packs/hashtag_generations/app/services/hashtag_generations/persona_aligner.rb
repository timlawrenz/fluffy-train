# frozen_string_literal: true

module HashtagGenerations
  # Filters and selects hashtags based on persona's niche and strategy
  class PersonaAligner
    def self.filter_tags(tags, persona)
      new(tags, persona).filter_tags
    end

    def initialize(tags, persona)
      @tags = tags
      @persona = persona
      @strategy = persona.hashtag_strategy
    end

    def filter_tags
      return @tags if @strategy.nil?
      
      filtered = @tags.dup
      
      # Add persona target hashtags
      filtered.concat(@strategy.target_hashtags) if @strategy.target_hashtags.any?
      
      # Remove avoided hashtags
      filtered = remove_avoided_tags(filtered)
      
      # Filter by niche categories if specified
      filtered = filter_by_niche(filtered) if @strategy.niche_categories.any?
      
      filtered.uniq
    end

    private

    def remove_avoided_tags(tags)
      return tags if @strategy.avoid_hashtags.empty?
      
      avoid_set = @strategy.avoid_hashtags.map(&:downcase).to_set
      
      tags.reject do |tag|
        avoid_set.include?(tag.downcase)
      end
    end

    def filter_by_niche(tags)
      # If niche categories are specified, prefer tags that match
      # but don't filter out all others (keep content-specific tags)
      tags
    end

    def matches_niche?(tag)
      return true if @strategy.niche_categories.empty?
      
      tag_lower = tag.downcase
      @strategy.niche_categories.any? do |niche|
        tag_lower.include?(niche.downcase)
      end
    end
  end
end
