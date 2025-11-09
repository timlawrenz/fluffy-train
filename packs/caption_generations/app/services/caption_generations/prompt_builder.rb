# frozen_string_literal: true

module CaptionGenerations
  class PromptBuilder
    def self.build(config:, context:, avoid_phrases: [])
      new(config: config, context: context, avoid_phrases: avoid_phrases).build
    end

    def initialize(config:, context:, avoid_phrases: [])
      @config = config
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
        You are a social media caption writer for Instagram. Your task is to write captions that:
        
        - Match the #{@config.tone} tone
        #{voice_attributes_text}
        #{style_instructions_text}
        #{topics_text}
        #{avoid_topics_text}
        
        IMPORTANT: Write engaging, authentic captions that tell a story or share a moment. 
        Good Instagram captions draw readers in and create connection.
        #{length_guidance_text}
        #{emoji_guidance_text}
        
        Write 3-5 sentences that feel natural and conversational. Share a thought, feeling, or observation.
        Create captions that are substantial enough to engage readers while maintaining authenticity.
        
        #{avoid_phrases_text}
      PROMPT
    end

    def build_user_prompt
      <<~PROMPT.strip
        Write an Instagram caption for this image. Look at the image carefully and incorporate what you see.
        
        #{context_text}
        
        #{example_captions_text}
        
        Generate a single caption that matches the style and tone described. 
        Write 3-5 complete sentences that tell a story or share a genuine moment.
        Do not include hashtags - they will be added separately.
      PROMPT
    end

    def voice_attributes_text
      return '' if @config.voice_attributes.empty?
      "- Voice qualities: #{@config.voice_attributes.join(', ')}"
    end

    def style_instructions_text
      return '' if @config.style.empty?
      instructions = []
      instructions << "use emoji" if @config.style[:use_emoji]
      instructions << "be conversational" if @config.tone == 'casual'
      instructions << "be professional" if @config.tone == 'professional'
      return '' if instructions.empty?
      "- Style: #{instructions.join(', ')}"
    end

    def topics_text
      return '' if @config.topics.empty?
      "- Preferred topics: #{@config.topics.join(', ')}"
    end

    def avoid_topics_text
      return '' if @config.avoid_topics.empty?
      "- Avoid these topics: #{@config.avoid_topics.join(', ')}"
    end

    def length_guidance_text
      case @config.style[:avg_length]
      when 'short'
        '- Target length: 200-350 characters (2-3 engaging sentences)'
      when 'medium'
        '- Target length: 350-550 characters (3-4 sentences with detail)'
      when 'long'
        '- Target length: 550-800 characters (4-6 sentences, rich narrative)'
      else
        '- Target length: 350-550 characters (3-4 sentences with detail)'
      end
    end

    def emoji_guidance_text
      return '- Do not use emoji' unless @config.style[:use_emoji]
      
      case @config.style[:emoji_density]
      when 'none'
        '- Do not use emoji'
      when 'low'
        '- Use 0-1 emoji sparingly'
      when 'moderate'
        '- Use 1-2 emoji naturally'
      when 'high'
        '- Use 2-3 emoji for emphasis'
      else
        '- Use 1-2 emoji naturally'
      end
    end

    def avoid_phrases_text
      return '' if @avoid_phrases.empty?
      phrases_list = @avoid_phrases.take(10).map { |p| "\"#{p}\"" }.join(', ')
      "- AVOID these recently used phrases: #{phrases_list}"
    end

    def context_text
      parts = []
      parts << "Theme: #{@context[:cluster_name]}" if @context[:cluster_name]
      parts << "Description: #{@context[:image_description]}" if @context[:image_description]
      parts.empty? ? '' : parts.join("\n")
    end

    def example_captions_text
      return '' if @config.example_captions.empty?
      
      examples = @config.example_captions.take(3).map.with_index do |example, i|
        "#{i + 1}. #{example}"
      end.join("\n")
      
      "Example captions in the desired style:\n#{examples}"
    end
  end
end
