# frozen_string_literal: true

module ContentStrategy
  class PreparePostContent
    attr_reader :persona, :strategy_name, :generate_caption

    def initialize(persona:, strategy_name: nil, generate_caption: true)
      @persona = persona
      @strategy_name = strategy_name
      @generate_caption = generate_caption
    end

    def call
      selection_result = select_next_photo
      return selection_result unless selection_result[:success]

      caption_result = build_caption(selection_result)

      {
        success: true,
        photo: selection_result[:photo],
        cluster: selection_result[:cluster],
        caption: caption_result[:text],
        caption_metadata: caption_result[:metadata],
        hashtags: selection_result[:hashtags],
        optimal_time: selection_result[:optimal_time],
        format: selection_result[:format],
        strategy_name: selection_result[:strategy_name]
      }
    end

    private

    def select_next_photo
      SelectNextPost.new(persona: persona, strategy_name: strategy_name).call
    end

    def build_caption(selection_result)
      photo = selection_result[:photo]
      cluster = selection_result[:cluster]
      hashtags = selection_result[:hashtags] || []

      if should_generate_caption?
        generate_ai_caption(photo, cluster, hashtags)
      else
        fallback_caption(photo, hashtags)
      end
    end

    def should_generate_caption?
      @generate_caption && persona.caption_config.present?
    end

    def generate_ai_caption(photo, cluster, hashtags)
      result = CaptionGenerations::Generator.generate(
        photo: photo,
        persona: persona,
        cluster: cluster
      )

      caption_with_hashtags = combine_caption_and_hashtags(result.text, hashtags)

      {
        text: caption_with_hashtags,
        metadata: result.metadata.merge(
          generated_by: 'ai',
          has_persona_config: true
        )
      }
    rescue StandardError => e
      Rails.logger.error("Caption generation failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      
      fallback_caption(photo, hashtags).merge(
        metadata: {
          generated_by: 'fallback',
          error: e.message,
          has_persona_config: true
        }
      )
    end

    def fallback_caption(photo, hashtags)
      base_caption = photo.photo_analysis&.caption || ''
      caption_text = combine_caption_and_hashtags(base_caption, hashtags)

      {
        text: caption_text,
        metadata: {
          generated_by: 'photo_analysis',
          has_persona_config: false
        }
      }
    end

    def combine_caption_and_hashtags(caption, hashtags)
      return hashtags.join(' ') if caption.blank?
      return caption if hashtags.empty?

      "#{caption}\n\n#{hashtags.join(' ')}"
    end
  end
end
