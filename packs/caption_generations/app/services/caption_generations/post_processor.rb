# frozen_string_literal: true

module CaptionGenerations
  class PostProcessor
    INSTAGRAM_MAX_LENGTH = 2200
    PROHIBITED_PATTERNS = [
      /click.*link.*bio/i,
      /dm.*for.*collab/i,
      /follow.*back/i
    ].freeze

    def self.process(caption, config)
      new(caption, config).process
    end

    def initialize(caption, config)
      @caption = caption
      @config = config
    end

    def process
      text = @caption.strip
      text = remove_prohibited_content(text)
      text = format_line_breaks(text)
      text = truncate_if_needed(text)
      text = adjust_emoji(text) if @config.style[:use_emoji]

      {
        text: text,
        quality_score: calculate_quality_score(text)
      }
    end

    private

    def remove_prohibited_content(text)
      PROHIBITED_PATTERNS.each do |pattern|
        if text.match?(pattern)
          Rails.logger.warn("Removed prohibited pattern: #{pattern}")
          text = text.gsub(pattern, '')
        end
      end
      text
    end

    def format_line_breaks(text)
      text.gsub(/\n{3,}/, "\n\n")
    end

    def truncate_if_needed(text)
      return text if text.length <= INSTAGRAM_MAX_LENGTH

      truncated = text[0, INSTAGRAM_MAX_LENGTH]
      last_period = truncated.rindex('.')
      last_space = truncated.rindex(' ')

      break_point = [last_period, last_space].compact.max || INSTAGRAM_MAX_LENGTH
      truncated[0, break_point].strip
    end

    def adjust_emoji(text)
      emoji_count = text.scan(/[\p{Emoji}]/).count
      target = emoji_target

      return text if emoji_count == target
      text
    end

    def emoji_target
      case @config.style[:emoji_density]
      when 'none' then 0
      when 'low' then 1
      when 'moderate' then 2
      when 'high' then 3
      else 2
      end
    end

    def calculate_quality_score(text)
      score = 5.0

      target_length = length_target(@config.style[:avg_length])
      length_diff = (text.length - target_length).abs
      score += 2.0 if length_diff < 20
      score += 1.0 if length_diff < 50

      emoji_count = text.scan(/[\p{Emoji}]/).count
      score += 1.0 if emoji_count > 0 && @config.style[:use_emoji]
      score -= 1.0 if emoji_count > 3

      score += 1.0 if text.include?("\n")

      [score, 10.0].min
    end

    def length_target(length_type)
      case length_type.to_s
      when 'short' then 80
      when 'medium' then 125
      when 'long' then 180
      else 125
      end
    end
  end
end
