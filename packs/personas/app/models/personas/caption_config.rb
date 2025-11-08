# frozen_string_literal: true

module Personas
  class CaptionConfig
    VALID_TONES = %w[casual professional playful inspirational edgy].freeze
    VALID_LENGTHS = %w[short medium long].freeze
    VALID_EMOJI_DENSITIES = %w[none low moderate high].freeze

    attr_accessor :tone, :voice_attributes, :style, :topics, :avoid_topics, :example_captions

    def initialize(attributes = {})
      @tone = attributes[:tone] || attributes['tone'] || 'casual'
      @voice_attributes = attributes[:voice_attributes] || attributes['voice_attributes'] || []
      @style = attributes[:style] || attributes['style'] || {}
      @topics = attributes[:topics] || attributes['topics'] || []
      @avoid_topics = attributes[:avoid_topics] || attributes['avoid_topics'] || []
      @example_captions = attributes[:example_captions] || attributes['example_captions'] || []

      normalize_style!
    end

    def valid?
      errors.empty?
    end

    def errors
      @errors ||= [].tap do |errs|
        unless VALID_TONES.include?(tone)
          errs << "tone must be one of: #{VALID_TONES.join(', ')}"
        end

        if style[:avg_length] && !VALID_LENGTHS.include?(style[:avg_length].to_s)
          errs << "avg_length must be one of: #{VALID_LENGTHS.join(', ')}"
        end

        if style[:emoji_density] && !VALID_EMOJI_DENSITIES.include?(style[:emoji_density].to_s)
          errs << "emoji_density must be one of: #{VALID_EMOJI_DENSITIES.join(', ')}"
        end
      end
    end

    def to_hash
      {
        tone: tone,
        voice_attributes: voice_attributes,
        style: style,
        topics: topics,
        avoid_topics: avoid_topics,
        example_captions: example_captions
      }
    end

    def self.from_hash(hash)
      return nil if hash.nil? || hash.empty?
      new(hash)
    end

    private

    def normalize_style!
      @style = @style.symbolize_keys if @style.respond_to?(:symbolize_keys)
      @style[:use_emoji] = @style[:use_emoji].nil? ? true : @style[:use_emoji]
      @style[:avg_length] ||= 'medium'
      @style[:emoji_density] ||= 'moderate'
    end
  end
end
