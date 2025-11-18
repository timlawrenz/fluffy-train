# frozen_string_literal: true

module CaptionGenerations
  class PromptBuilder
    def self.build(persona:, context:, avoid_phrases: [])
      new(persona: persona, context: context, avoid_phrases: avoid_phrases).build
    end

    def initialize(persona:, context:, avoid_phrases: [])
      @persona = persona
      @config = persona.caption_config
      @context = context
      @avoid_phrases = avoid_phrases
    end

    def build
      {
        system: build_system_prompt,
        user: build_user_prompt
      }
    end

    private

    def build_system_prompt
      <<~PROMPT.strip
        You are a social media caption writer for Instagram. 
        
        IMPORTANT: Write engaging, authentic captions that tell a rich story or share a meaningful moment. 
        Good Instagram captions draw readers in, create connection, and provide genuine value.
        
        Write 4-7 sentences that feel natural and conversational. Share thoughts, feelings, observations, or context.
        Create captions that are substantial, engaging, and authentic - don't be afraid to add personality and detail.
        Paint a picture with words that complements what's in the photo.
        
        You will receive detailed JSON configuration about the persona's voice, style preferences, and the photo context.
        Use this information to craft the perfect caption.
      PROMPT
    end

    def build_user_prompt
      <<~PROMPT.strip
        Please generate a caption for Instagram for the attached photo.
        
        PERSONA CAPTION STRATEGY:
        ```json
        #{persona_caption_config_json}
        ```
        
        PERSONA HASHTAG STRATEGY:
        ```json
        #{persona_hashtag_strategy_json}
        ```
        
        PHOTO ANALYSIS:
        ```json
        #{photo_context_json}
        ```
        
        #{cluster_context_json}
        
        #{avoid_phrases_json}
        
        Generate a single caption that matches the persona's voice and style from the JSON configuration above.
        Look at the photo carefully and incorporate specific details you see in the detected objects.
        Write 4-7 complete sentences that tell a rich story or share a genuine, detailed moment.
        Be specific about what you observe in the image to create authentic connection.
        Do not include hashtags - they will be added separately.
      PROMPT
    end

    private

    def persona_caption_config_json
      # Use the raw caption_config JSON directly from the database
      JSON.pretty_generate(@config.to_hash)
    end

    def persona_hashtag_strategy_json
      # Use the raw hashtag_strategy JSON directly from the database
      return JSON.pretty_generate({note: "No hashtag strategy configured"}) unless @persona.hashtag_strategy
      JSON.pretty_generate(@persona.hashtag_strategy.to_hash)
    end

    def photo_context_json
      context_data = {
        image_description: @context[:image_description],
        aesthetic_score: @context.dig(:photo_analysis, :aesthetic_score),
        detected_objects: @context.dig(:photo_analysis, :detected_objects)
      }.compact
      
      JSON.pretty_generate(context_data)
    end

    def cluster_context_json
      return '' unless @context[:cluster_data]
      
      <<~CONTEXT.strip
        CLUSTER/THEME CONTEXT:
        ```json
        #{JSON.pretty_generate(@context[:cluster_data])}
        ```
      CONTEXT
    end

    def avoid_phrases_json
      return '' if @avoid_phrases.empty?
      
      phrases_data = {
        instruction: "Avoid using these recently used phrases",
        phrases: @avoid_phrases.take(10)
      }
      
      <<~AVOID.strip
        REPETITION AVOIDANCE:
        ```json
        #{JSON.pretty_generate(phrases_data)}
        ```
      AVOID
    end

    def length_target_description(length_type)
      case length_type.to_s
      when 'short' then '3-4 sentences'
      when 'medium' then '4-6 sentences'  
      when 'long' then '6-8 sentences'
      else '4-6 sentences'
      end
    end

    def length_target(length_type)
      case length_type.to_s
      when 'short' then 375
      when 'medium' then 575
      when 'long' then 850
      else 575
      end
    end
  end
end
