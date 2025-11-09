# TUI AI-Powered Content Workflow

## Overview

The TUI (Terminal User Interface) now integrates AI to streamline content creation with a pillar-based approach.

## Key Concept: Pillars → Clusters → Photos → Posts

1. **Content Pillars**: Strategic themes with target weights (e.g., "Thanksgiving 2024 Gratitude" at 30%)
2. **Clusters**: Small sets of 10-30 related photos feeding into one or more pillars
3. **AI-Generated Clusters**: Clusters created with embedded generation prompts
4. **Photos**: Actual images imported and added to clusters
5. **Scheduled Posts**: Content pulled from appropriate clusters based on pillar weights

## AI Workflow

### Step 1: Generate Cluster Suggestions (AI)
```
bin/fluffy-tui sarah
→ 🤖 AI Content Suggestions
→ Generate cluster suggestions for a pillar
```

AI (Ollama + Gemma 3) generates:
- Cluster names (based on scene descriptions)
- Full image generation prompts with scene, outfit, and mood details
- Automatically creates clusters linked to selected pillar
- Stores prompts in `clusters.ai_prompt` field

### Step 2: Generate Images (External)
Use the AI prompts with:
- ComfyUI
- Stable Diffusion
- DALL-E
- Midjourney
etc.

### Step 3: Import Photos
```bash
bin/import sarah /path/to/generated/images
```

### Step 4: Add Photos to Clusters (TUI)
```
bin/fluffy-tui sarah
→ 🎯 Pillars & Clusters
→ Select cluster
→ Add photos
```

### Step 5: Schedule Posts (TUI)
```
bin/fluffy-tui sarah
→ 📅 Schedule Post
```

System automatically:
- Selects pillar based on weights and gaps
- Picks cluster from that pillar
- Chooses unposted photo
- Generates caption with Gemini 2.5 Pro (multimodal)
- Schedules for next posting time

## Features

### Dashboard View
- Shows pillar distribution and gaps
- Displays scheduled posts (upcoming 7 days)
- Shows next actions with keyboard shortcuts
- Tree view of pillars → clusters

### Pillar & Cluster Management
- Create/edit pillars with weights
- Create/edit clusters
- Link clusters to multiple pillars
- View unlinked clusters
- Add photos to clusters (with full paths shown)

### AI Integration
- **Ollama + Gemma 3**: Generate creation prompts (local, free)
- **Gemini 2.5 Pro**: Generate captions from images (multimodal, paid API)

### Caption Generation
- Multimodal: analyzes actual photo content
- Persona-aware: uses persona's voice and style
- Pillar-aware: incorporates pillar context
- Configurable length (targets 2-3 paragraphs)
- Includes hashtags from photo metadata

## Automated Posting

Cron job runs daily:
```bash
0 * * * * /home/tim/source/activity/fluffy-train/bin/scheduled_posting.sh
```

No TUI interaction needed for daily publishing.

## Current Status

### Working
✅ Dashboard with pillar/cluster tree view
✅ Pillar CRUD operations
✅ Cluster CRUD operations
✅ Link clusters to pillars (many-to-many)
✅ Add photos to clusters
✅ AI cluster generation with embedded prompts
✅ Schedule posts with AI captions
✅ Cleanup overdue posts
✅ Automated daily posting (cron)

### Skipped for Now
⏸️ Manual caption editing in TUI (can edit in DB if needed)
⏸️ Publish pending view (handled by cron)
⏸️ Multiple persona support in single TUI session

## Next Steps

1. Test AI cluster generation end-to-end
2. Generate images using the prompts
3. Import and cluster the photos
4. Monitor posting over next week
5. Iterate on prompts and pillar weights based on performance

## Philosophy

Small, focused clusters (10-30 photos) feeding into strategic pillars enables:
- **Variety**: Multiple clusters per pillar prevents repetition
- **Quality**: Easier to curate smaller sets
- **Strategy**: Rotate between clusters within a pillar
- **Freshness**: Diverse content from single theme
- **AI Leverage**: Generate new cluster ideas when running low

The system is now ready for Sarah to start posting again! 🎉
