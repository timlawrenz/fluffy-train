# Caption Prompt Improvements - 2025-11-18

## Problem

The previous caption generation prompts were verbose, prose-heavy, and didn't leverage the structured data we have in the database.

**Issues:**
- Prose-based instructions mixed with manually constructed data
- Didn't use the raw JSON from `persona.caption_config` and `persona.hashtag_strategy`
- Missing rich photo analysis data (detected objects, aesthetic scores)
- Missing cluster context

## Solution

Changed to use **raw database JSON** directly - providing the actual `caption_config` and `hashtag_strategy` JSON blobs exactly as stored in the database.

**New approach:**
- Use `persona.caption_config.to_hash` directly
- Use `persona.hashtag_strategy.to_hash` directly  
- Include photo analysis metadata (detected objects, scores)
- Include cluster context
- Clean, minimal system prompt

## What Changed

### 1. ContextBuilder Enhancement

**File:** `packs/caption_generations/app/services/caption_generations/context_builder.rb`

**Added:**
- `photo_analysis_data` - aesthetic score and top 5 detected objects with confidence
- `cluster_data` - cluster name and AI prompt (if available)

### 2. PromptBuilder Refactor

**File:** `packs/caption_generations/app/services/caption_generations/prompt_builder.rb`

**Changed:**
- Now accepts `persona:` instead of `config:` to access both config objects
- Uses `persona.caption_config.to_hash` for raw JSON
- Uses `persona.hashtag_strategy.to_hash` for raw JSON
- Removed manual JSON construction
- Simplified system prompt

**Old:**
```ruby
PromptBuilder.build(
  config: persona.caption_config,
  context: context,
  avoid_phrases: []
)
```

**New:**
```ruby
PromptBuilder.build(
  persona: persona,
  context: context,
  avoid_phrases: []
)
```

## New Prompt Structure

### User Prompt
```
Please generate a caption for Instagram for the attached photo.

PERSONA CAPTION STRATEGY:
```json
{
  "tone": "casual",
  "voice_attributes": ["authentic", "warm", "curious", "understated", "graceful"],
  "style": {
    "use_emoji": true,
    "avg_length": "medium",
    "emoji_density": "low"
  },
  "topics": ["fashion as self-expression", "everyday moments", ...],
  "avoid_topics": ["overt sexuality", "body-focused content", ...],
  "example_captions": ["Just found the perfect corner...", ...]
}
```

PERSONA HASHTAG STRATEGY:
```json
{
  "niche_categories": ["lifestyle", "fashion", "urban", "coffee", "creativity"],
  "target_hashtags": ["#LifestylePhotography", "#FashionDaily", ...],
  "avoid_hashtags": ["#Like4Like", "#FollowForFollow", "#Spam"],
  "size_mix": "balanced"
}
```

PHOTO ANALYSIS:
```json
{
  "image_description": "Coffee breaks are the best kind of break! ☕️✨",
  "aesthetic_score": 8.0,
  "detected_objects": [
    {"label": "person", "confidence": 0.97},
    {"label": "woman", "confidence": 0.95},
    {"label": "cup", "confidence": 0.85}
  ]
}
```

CLUSTER/THEME CONTEXT:
```json
{
  "name": "flower shopping in paris"
}
```

Generate a single caption that matches the persona's voice and style from the JSON configuration above.
Look at the photo carefully and incorporate specific details you see in the detected objects.
Write 4-7 complete sentences that tell a rich story or share a genuine, detailed moment.
Be specific about what you observe in the image to create authentic connection.
Do not include hashtags - they will be added separately.
```

## Benefits

1. **Uses Actual Database Values** - No manual JSON construction, uses raw DB fields
2. **More Context** - Includes hashtag strategy, detected objects, aesthetic scores
3. **Better AI Understanding** - JSON is easier for AI models to parse
4. **Cleaner Code** - Let the model objects serialize themselves
5. **Easier Debugging** - Can see exactly what's in the database
6. **Matches Manual Testing** - Same pattern that works in Gemini UI

## Testing

```bash
rails runner "
persona = Persona.find_by(name: 'sarah')
photo = Photo.includes(:photo_analysis, :cluster).where.not(cluster_id: nil).first

context = CaptionGenerations::ContextBuilder.build(photo: photo, cluster: photo.cluster)
prompt = CaptionGenerations::PromptBuilder.build(
  persona: persona,
  context: context,
  avoid_phrases: []
)

puts prompt[:user]
"
```

## Backward Compatibility

⚠️ **Breaking change in PromptBuilder API** but internal only:
- Changed `config:` parameter to `persona:`
- Only called from `Generator.generate()` which was updated
- No external API changes - `Generator.generate()` signature unchanged

---

**Date:** 2025-11-18
**Impact:** Improved caption generation by using raw database JSON directly
