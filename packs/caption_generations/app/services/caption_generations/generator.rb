# frozen_string_literal: true

module CaptionGenerations
  class Generator
    def self.generate(photo:, persona:, cluster: nil, options: {})
      new(photo: photo, persona: persona, cluster: cluster, options: options).generate
    end

    def initialize(photo:, persona:, cluster: nil, options: {})
      @photo = photo
      @persona = persona
      @cluster = cluster
      @options = options
    end

    def generate
      raise ArgumentError, 'Persona caption_config is required' unless @persona.caption_config

      context = ContextBuilder.build(photo: @photo, cluster: @cluster)
      recent_captions = fetch_recent_captions
      repetition_avoid_list = RepetitionChecker.extract_phrases(recent_captions)

      prompt = PromptBuilder.build(
        config: @persona.caption_config,
        context: context,
        avoid_phrases: repetition_avoid_list
      )

      variations_count = @options[:variations] || 1
      captions = generate_variations(prompt, variations_count)

      selected_caption = select_best_caption(captions)
      processed = PostProcessor.process(selected_caption, @persona.caption_config)

      Result.new(
        text: processed[:text],
        metadata: build_metadata(processed, captions),
        variations: captions
      )
    end

    private

    def fetch_recent_captions
      Scheduling::Post
        .where(persona_id: @persona.id)
        .where.not(caption: [nil, ''])
        .order(created_at: :desc)
        .limit(20)
        .pluck(:caption)
    end

    def generate_variations(prompt, count)
      count.times.map do
        ollama_generate_caption(prompt)
      end
    end

    def ollama_generate_caption(prompt)
      client = OllamaClient.new
      client.generate_caption_with_prompt(
        file_path: @photo.path,
        system_prompt: prompt[:system],
        user_prompt: prompt[:user]
      )
    rescue StandardError => e
      Rails.logger.error("Caption generation failed: #{e.message}")
      TemplateGenerator.generate(
        cluster: @cluster,
        config: @persona.caption_config
      )
    end

    def select_best_caption(captions)
      captions.max_by { |caption| score_caption(caption) }
    end

    def score_caption(caption)
      score = 0
      target_length = length_target(@persona.caption_config.style[:avg_length])
      score += 100 - (caption.length - target_length).abs
      score += caption.scan(/[\p{Emoji}]/).count * 5 if @persona.caption_config.style[:use_emoji]
      score
    end

    def length_target(length_type)
      case length_type.to_s
      when 'short' then 80
      when 'medium' then 125
      when 'long' then 180
      else 125
      end
    end

    def build_metadata(processed, variations)
      {
        method: 'ai_generated',
        model: 'gemma3:27b',
        generated_at: Time.current,
        quality_score: processed[:quality_score],
        variations: variations.count,
        processor_version: '1.0'
      }
    end
  end
end
