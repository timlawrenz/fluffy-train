# Gemini API Setup

## Environment Variable

The TUI requires the `GEMINI_API_KEY` environment variable to be set for AI-powered features:

```bash
export GEMINI_API_KEY="your-api-key-here"
```

Add this to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) to persist across sessions.

## Model Used

The application uses `gemini-1.5-pro-latest` for:
- Cluster suggestion generation  
- Caption generation with image analysis (multimodal)
- Content prompt creation

## Testing

To verify the API key is working:

```bash
bundle exec ruby -e "
require_relative 'lib/ai/gemini_client'
client = AI::GeminiClient.new
puts client.generate_text('Hello world', max_tokens: 20)
"
```

## Features Using Gemini

1. **AI Content Suggestions** - Generate cluster ideas with creation prompts
2. **Caption Generation** - Create Instagram captions analyzing the actual photo
3. **Prompt Engineering** - Generate detailed AI image generation prompts

All features gracefully degrade if the API key is not available.
