# Caption Generations Pack

This pack provides persona-driven caption generation for Instagram posts using AI.

## Features

- Persona-specific voice and tone configuration
- Context-aware caption generation (cluster themes, image descriptions)
- Repetition avoidance across recent captions
- Instagram compliance validation
- Quality scoring and metadata tracking

## Components

- `Personas::CaptionConfig` - Configuration model for persona voice/style
- `CaptionGenerations::Generator` - Main generation service
- `CaptionGenerations::PromptBuilder` - AI prompt construction
- `CaptionGenerations::ContextBuilder` - Context extraction
- `CaptionGenerations::PostProcessor` - Validation and formatting
- `CaptionGenerations::RepetitionChecker` - Phrase deduplication
