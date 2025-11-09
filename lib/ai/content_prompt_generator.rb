# frozen_string_literal: true

require_relative 'gemini_client'

module AI
  class ContentPromptGenerator
    def initialize(persona)
      @persona = persona
      @client = GeminiClient.new
    end
    
    def generate_creation_prompts(pillar, count: 3)
      return [] unless @client.available?
      
      system_prompt = build_system_prompt
      user_prompt = build_user_prompt(pillar, count)
      
      full_prompt = "#{system_prompt}\n\n#{user_prompt}"
      
      response = @client.generate_text(full_prompt, temperature: 0.8, max_tokens: 3000)
      parse_prompts(response)
    rescue => e
      puts "AI prompt generation failed: #{e.message}" if defined?(Rails)
      []
    end
    
    def generate_single_prompt(pillar, context: nil)
      prompts = generate_creation_prompts(pillar, count: 1)
      prompts.first
    end
    
    private
    
    def build_system_prompt
      <<~SYSTEM
        You are an expert AI image generation prompt engineer specializing in Instagram content creation.
        
        Your task is to create detailed, specific prompts for AI image generation tools (like Stable Diffusion, Midjourney, DALL-E).
        
        Key requirements for your prompts:
        1. **Scene Description**: Describe the setting, environment, lighting, and atmosphere in detail
        2. **Outfit/Appearance**: Specify clothing, style, colors, and accessories
        3. **Pose/Action**: Describe what the person is doing, their expression, and body language
        4. **Photography Style**: Mention camera angle, focal length, depth of field, and aesthetic
        5. **Mood/Vibe**: Capture the emotional tone and overall feeling
        
        Format each prompt as a single paragraph, rich in visual details but natural-sounding.
        Include technical photography terms when relevant (golden hour, bokeh, shallow depth of field, etc.).
        
        Output format:
        For each prompt, use this structure:
        
        **Prompt N:**
        [Full detailed prompt here]
        
        **Scene:** [Brief scene summary]
        **Outfit:** [Key outfit details]
        **Mood:** [Emotional tone]
        
        ---
      SYSTEM
    end
    
    def build_user_prompt(pillar, count)
      persona_context = build_persona_context
      pillar_context = build_pillar_context(pillar)
      examples = build_examples(pillar)
      
      <<~USER
        Generate #{count} AI image generation prompts for Instagram content.
        
        #{persona_context}
        
        #{pillar_context}
        
        #{examples}
        
        Create #{count} diverse, specific prompts that:
        - Align with the persona's aesthetic and content pillar theme
        - Include detailed scene descriptions (location, lighting, time of day)
        - Specify outfit details (style, colors, fabrics, accessories)
        - Describe the mood and atmosphere
        - Are suitable for AI image generation
        - Feel authentic and natural, not staged or overly posed
        
        Make each prompt unique and capture different angles on the pillar theme.
      USER
    end
    
    def build_persona_context
      # Extract from caption config if available
      caption_cfg = @persona.caption_config
      aesthetic = "Contemporary, authentic, relatable"
      voice_attrs = caption_cfg&.voice_attributes || []
      voice = voice_attrs.is_a?(Array) ? voice_attrs.join(', ') : "Warm, genuine, thoughtful"
      
      <<~CONTEXT
        **Persona:** #{@persona.name}
        **Aesthetic:** #{aesthetic}
        **Voice/Vibe:** #{voice}
        **Age/Demo:** Young adult, urban professional
        **Platform:** Instagram (focus on visual storytelling)
      CONTEXT
    end
    
    def build_pillar_context(pillar)
      guidelines_hash = pillar.guidelines || {}
      topics = guidelines_hash['topics'] || guidelines_hash[:topics] || []
      tone = guidelines_hash['tone'] || guidelines_hash[:tone] || []
      
      guidelines_text = "Create authentic, relatable content"
      guidelines_text += " with #{tone.join(', ')} tone" if tone.any?
      
      examples_text = topics.join(", ") if topics.is_a?(Array) && topics.any?
      examples_text ||= "everyday moments with meaning"
      
      <<~CONTEXT
        **Content Pillar:** #{pillar.name} (#{pillar.weight}% of content)
        **Theme:** #{guidelines_text}
        **Example Topics:** #{examples_text}
      CONTEXT
    end
    
    def build_examples(pillar)
      # Add context from Thanksgiving plan if relevant
      if pillar.name.downcase.include?('thanksgiving') || pillar.name.downcase.include?('gratitude')
        return <<~EXAMPLES
          **Reference Examples:**
          
          1. "Morning coffee with soft autumn light streaming through window, wearing cozy cream knit sweater, 
             hands wrapped around ceramic mug, gentle smile, peaceful morning atmosphere, warm tones, 
             shallow depth of field, lifestyle photography aesthetic"
          
          2. "Neighborhood café scene, woman sitting by large window with fall foliage visible outside, 
             reading book with coffee cup on wooden table, wearing camel-colored coat, natural daylight, 
             candid moment, urban autumn vibes, documentary photography style"
          
          3. "Cozy home interior, woman on sofa with blanket and book, warm ambient lighting from candles and lamp, 
             wearing comfortable loungewear in neutral tones, peaceful evening atmosphere, hygge aesthetic, 
             soft focus, intimate lifestyle photography"
        EXAMPLES
      end
      
      # Generic examples for other pillars
      <<~EXAMPLES
        **Style Guidelines:**
        - Natural, authentic moments (not overly posed)
        - Soft, flattering lighting (golden hour, window light, warm indoor lighting)
        - Relatable settings (cafes, home, neighborhood, parks)
        - Contemporary, minimalist aesthetic
        - Warm, inviting color palette
      EXAMPLES
    end
    
    def parse_prompts(response)
      prompts = []
      
      # Split by the --- separator or "**Prompt" markers
      sections = response.split(/---|\*\*Prompt \d+:\*\*/).reject(&:empty?)
      
      sections.each do |section|
        next if section.strip.empty?
        
        # Extract components
        full_prompt = extract_content(section, /^(.+?)(?:\*\*Scene:|$)/m)
        scene = extract_content(section, /\*\*Scene:\*\*\s*(.+?)(?:\*\*|$)/m)
        outfit = extract_content(section, /\*\*Outfit:\*\*\s*(.+?)(?:\*\*|$)/m)
        mood = extract_content(section, /\*\*Mood:\*\*\s*(.+?)(?:\*\*|$)/m)
        
        if full_prompt && !full_prompt.strip.empty?
          prompts << {
            full_prompt: full_prompt.strip,
            scene: scene&.strip,
            outfit: outfit&.strip,
            mood: mood&.strip
          }
        end
      end
      
      # Fallback: if structured parsing failed, try to extract paragraphs
      if prompts.empty?
        paragraphs = response.split(/\n\n+/).reject { |p| p.strip.empty? || p.strip.length < 50 }
        paragraphs.first(3).each do |para|
          prompts << {
            full_prompt: para.strip,
            scene: nil,
            outfit: nil,
            mood: nil
          }
        end
      end
      
      prompts
    end
    
    def extract_content(text, regex)
      match = text.match(regex)
      match ? match[1].strip : nil
    end
  end
end
