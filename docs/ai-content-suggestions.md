# AI-Powered Content Suggestion System

## Overview

Fluffy-train now includes an AI-powered content prompt generation system that uses **Ollama** + **Gemma 3** to create detailed image generation prompts aligned with your persona and content pillars.

## Features

### 🤖 Intelligent Prompt Generation

The system generates detailed prompts for AI image generation tools (Stable Diffusion, Midjourney, DALL-E) that include:

- **Scene Description**: Setting, environment, lighting, time of day, atmosphere
- **Outfit Details**: Clothing style, colors, fabrics, accessories
- **Pose/Action**: What the subject is doing, expressions, body language
- **Photography Style**: Camera angle, focal length, depth of field, aesthetic
- **Mood/Vibe**: Emotional tone and overall feeling

### 📋 Persona-Aware Context

Each prompt is generated with full awareness of:
- Persona's aesthetic guidelines and voice
- Content pillar themes and topics
- Seasonal relevance and boost factors
- Example reference styles

### 💾 Save & Review

- Save prompts to markdown files for future reference
- View previously generated prompts
- Organized by persona and pillar

## Setup

### Prerequisites

1. **Install Ollama**: https://ollama.ai
   ```bash
   curl https://ollama.ai/install.sh | sh
   ```

2. **Pull Gemma 3 model** (4B variant recommended):
   ```bash
   ollama pull gemma3:latest
   ```

3. **Verify Ollama is running**:
   ```bash
   ollama list
   ```

The system uses `gemma3:latest` (4B parameters) by default for memory efficiency. You can also use `gemma3:27b` for higher quality if you have sufficient GPU memory (16GB+).

## Usage

### Via TUI

1. Launch the TUI:
   ```bash
   bin/fluffy-tui sarah
   ```

2. Select **"🤖 AI Content Suggestions"** from the main menu

3. Choose **"Generate prompts for a pillar"**

4. Select which content pillar to generate prompts for

5. Specify how many prompts (1-5)

6. Wait 30-60 seconds for generation

7. Review prompts with scene/outfit/mood breakdowns

8. Optionally save to `docs/ai-prompts/`

### Programmatic Usage

```ruby
require_relative 'lib/ai/content_prompt_generator'

persona = Persona.find_by(name: 'sarah')
pillar = persona.content_pillars.find { |p| p.name.include?('Thanksgiving') }

generator = AI::ContentPromptGenerator.new(persona)
prompts = generator.generate_creation_prompts(pillar, count: 3)

prompts.each do |prompt|
  puts prompt[:full_prompt]
  puts "Scene: #{prompt[:scene]}"
  puts "Outfit: #{prompt[:outfit]}"
  puts "Mood: #{prompt[:mood]}"
end
```

### Test Script

Quick test to verify AI integration:

```bash
bin/test-ai
```

## Example Output

```
PROMPT 1:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┃ Image Generation Prompt                                                    ┃
┃                                                                              ┃
┃ A golden hour shot of Sarah sitting at a rustic wooden farmhouse table,    ┃
┃ lit by the warm glow of a single beeswax candle. Outside, a light rain is  ┃
┃ falling, creating a blurred, impressionistic effect on the wet fields of   ┃
┃ harvested pumpkins and corn stalks. Sarah is wearing a chunky cream-colored┃
┃ cable knit sweater (wool blend), dark wash vintage-style jeans, and brown  ┃
┃ leather ankle boots. She's gently arranging a small bouquet of dried autumn┃
┃ leaves and berries in a simple ceramic vase. Her expression is serene and  ┃
┃ thoughtful, a slight smile playing on her lips as she observes the scene.  ┃
┃ The camera is positioned at a slightly low angle, creating a sense of      ┃
┃ intimacy and warmth. Use a shallow depth of field to blur the background   ┃
┃ and emphasize Sarah and the arrangement. Aim for a 'documentary            ┃
┃ photography' aesthetic, capturing a genuine, quiet moment of gratitude.    ┃
┃ Soft focus, muted color palette (ochre, sage green, cream). 85mm lens.     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  📍 Scene: Autumn Harvest Gratitude
  👗 Outfit: Chunky Cream Cable Knit Sweater, Dark Wash Vintage Jeans, Brown Ankle Boots
  ✨ Mood: Reflective, Peaceful, Grateful
```

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      TUI / Application Layer                 │
│                   (ai_prompts_view.rb)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│               AI::ContentPromptGenerator                     │
│         (content_prompt_generator.rb)                       │
│                                                              │
│  • Builds persona context (aesthetic, voice, demographics)  │
│  • Builds pillar context (theme, topics, examples)          │
│  • Crafts detailed system + user prompts                    │
│  • Parses structured AI responses                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                   AI::OllamaClient                           │
│                 (ollama_client.rb)                          │
│                                                              │
│  • HTTP client for Ollama API (Faraday)                     │
│  • Supports /api/generate and /api/chat endpoints           │
│  • Handles temperature, token limits, streaming             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    Ollama Service                            │
│                 (localhost:11434)                           │
│                                                              │
│  • Runs gemma3:latest (4B param model)                      │
│  • GPU-accelerated inference                                 │
│  • Local, private, no external API calls                    │
└─────────────────────────────────────────────────────────────┘
```

### Prompt Engineering

The system uses a two-stage prompt:

1. **System Prompt**: Establishes role as expert prompt engineer with specific formatting requirements

2. **User Prompt**: Provides:
   - Persona context (name, aesthetic, voice, demographics)
   - Pillar context (theme, weight, topics, guidelines)
   - Reference examples (especially for Thanksgiving/gratitude content)
   - Requirements (scene, outfit, mood, photography style)

### Response Parsing

The AI response is parsed to extract:
- Full detailed prompt (primary output)
- Scene summary (extracted from `**Scene:**` marker)
- Outfit details (extracted from `**Outfit:**` marker)
- Mood description (extracted from `**Mood:**` marker)

Fallback: If structured parsing fails, extracts paragraphs as standalone prompts.

## Workflow Integration

### Recommended Process

1. **Analyze Content Gaps** (Dashboard view)
   - See which pillars need content
   - Identify missing photos for upcoming posts

2. **Generate AI Prompts** (AI Suggestions view)
   - Select pillar with content gap
   - Generate 2-3 prompts
   - Save prompts for reference

3. **Create Images** (External AI tool)
   - Use Stable Diffusion / Midjourney / DALL-E
   - Feed in generated prompts
   - Generate multiple variations

4. **Import & Curate** (Photo import)
   - Import generated images
   - Review quality and persona alignment
   - Discard off-brand content

5. **Create Cluster** (Pillars & Clusters view)
   - Create new cluster for pillar
   - Add curated photos to cluster
   - Link cluster to pillar

6. **Schedule Posts** (Schedule view)
   - Select from pillar-appropriate clusters
   - Generate captions
   - Schedule according to strategy

## Configuration

### Change AI Model

Edit `lib/ai/ollama_client.rb`:

```ruby
DEFAULT_MODEL = 'gemma3:latest'  # 4B model (recommended)
# Or for higher quality:
DEFAULT_MODEL = 'gemma3:27b'     # 27B model (requires 16GB+ GPU memory)
# Or other models:
DEFAULT_MODEL = 'mistral-small:24b'
DEFAULT_MODEL = 'llama2:7b'
```

### Adjust Generation Parameters

In `lib/ai/content_prompt_generator.rb`:

```ruby
# Increase creativity (more variation, less predictable)
response = @client.chat(messages, temperature: 0.9, max_tokens: 3000)

# Decrease creativity (more focused, predictable)
response = @client.chat(messages, temperature: 0.5, max_tokens: 3000)
```

### Customize Prompts

Modify `build_examples(pillar)` method to add pillar-specific examples:

```ruby
if pillar.name.downcase.include?('fitness')
  return <<~EXAMPLES
    **Reference Examples:**
    
    1. "Yoga studio with natural morning light..."
    2. "Outdoor workout in park setting..."
  EXAMPLES
end
```

## Troubleshooting

### "No prompts generated. Check Ollama connectivity."

```bash
# Verify Ollama is running
systemctl status ollama

# Or manually start
ollama serve

# Test API
curl http://localhost:11434/api/tags
```

### "CUDA error: out of memory"

Your GPU doesn't have enough memory for gemma3:27b. Switch to smaller model:

```bash
# Use 4B model instead
ollama pull gemma3:latest
```

Then update `lib/ai/ollama_client.rb` to use `gemma3:latest`.

### Slow generation (>2 minutes)

- Check GPU utilization: `nvidia-smi`
- Reduce max_tokens to 2000
- Use smaller model
- Close other GPU-intensive applications

### Poor prompt quality

- Try temperature: 0.7-0.9 (higher = more creative)
- Add more reference examples in `build_examples()`
- Use larger model (gemma3:27b or mistral-small:24b)
- Refine persona aesthet ic/voice guidelines

## Future Enhancements

### Planned Features

- [ ] **Caption generation**: AI-powered captions aligned with prompts
- [ ] **Hashtag suggestions**: Generate strategic hashtags
- [ ] **Photo analysis**: Analyze existing photos and suggest similar prompts
- [ ] **Batch generation**: Generate full week's prompts at once
- [ ] **Prompt refinement**: Iteratively improve prompts based on feedback
- [ ] **Style transfer**: Learn from existing photos to match visual style

### Advanced Ideas

- **Multi-modal**: Use vision models to analyze successful posts
- **A/B testing**: Generate variants and track performance
- **Seasonal awareness**: Auto-adjust prompts for holidays/seasons
- **Persona evolution**: Learn from engagement to refine style over time

## Files Created

```
lib/ai/
  ├── ollama_client.rb              # HTTP client for Ollama API
  └── content_prompt_generator.rb   # Prompt engineering & generation

lib/tui/views/
  └── ai_prompts_view.rb            # TUI interface for AI suggestions

bin/
  └── test-ai                        # Quick test script

docs/ai-prompts/                    # Saved prompts (auto-created)
```

## See Also

- [Content Pillar System](../docs/research/content-strategy-engine/content-pillars-clusters-guide.md)
- [Sarah's Thanksgiving Plan](../docs/content-plans/sarah-thanksgiving-2024.md)
- [TUI Development Spec](../openspec/changes/add-tui-interface.md)
- [Ollama Documentation](https://ollama.ai)
- [Gemma Models](https://ai.google.dev/gemma)
