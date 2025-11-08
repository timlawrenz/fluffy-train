# frozen_string_literal: true

module Personas
  class HashtagStrategy
    VALID_SIZE_MIX = %w[balanced niche_heavy broad_reach].freeze

    attr_accessor :niche_categories, :target_hashtags, :avoid_hashtags, :size_mix

    def initialize(attributes = {})
      @niche_categories = attributes[:niche_categories] || attributes['niche_categories'] || []
      @target_hashtags = attributes[:target_hashtags] || attributes['target_hashtags'] || []
      @avoid_hashtags = attributes[:avoid_hashtags] || attributes['avoid_hashtags'] || []
      @size_mix = attributes[:size_mix] || attributes['size_mix'] || 'balanced'
    end

    def valid?
      errors.empty?
    end

    def errors
      @errors ||= [].tap do |errs|
        unless VALID_SIZE_MIX.include?(size_mix)
          errs << "size_mix must be one of: #{VALID_SIZE_MIX.join(', ')}"
        end

        if target_hashtags.any? { |tag| !valid_hashtag_format?(tag) }
          errs << "target_hashtags must be valid hashtag format (#word)"
        end

        if avoid_hashtags.any? { |tag| !valid_hashtag_format?(tag) }
          errs << "avoid_hashtags must be valid hashtag format (#word)"
        end
      end
    end

    def to_hash
      {
        niche_categories: niche_categories,
        target_hashtags: target_hashtags,
        avoid_hashtags: avoid_hashtags,
        size_mix: size_mix
      }
    end

    def self.from_hash(hash)
      return nil if hash.nil? || hash.empty?
      new(hash)
    end

    def size_distribution
      case size_mix
      when 'balanced'
        { large: 2..3, medium: 3..4, niche: 3..5 }
      when 'niche_heavy'
        { large: 1..2, medium: 2..3, niche: 5..7 }
      when 'broad_reach'
        { large: 3..4, medium: 3..4, niche: 2..3 }
      else
        { large: 2..3, medium: 3..4, niche: 3..5 }
      end
    end

    private

    def valid_hashtag_format?(tag)
      tag.to_s.match?(/^#[a-zA-Z0-9]+$/)
    end
  end
end
