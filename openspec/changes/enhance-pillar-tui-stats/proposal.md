# Change: Enhance Pillar TUI Stats

## Why
When generating AI content suggestions, it is crucial to know not just the total number of photos in a pillar, but how many are *unposted*. This helps the user prioritize content creation for pillars that are running low on fresh content. Additionally, providing a recommendation on which pillar needs content the most (based on strategy gaps) guides the user towards the most impactful actions.

## What Changes
- **Modified TUI View**: `TUI::Views::AIPromptsView`
  - Update the pillar selection list to show "unposted photos" count instead of or in addition to "total photos".
  - Integrate `ContentPillars::GapAnalyzer` to identify the pillar with the most critical content gap.
  - Pre-select or highlight the recommended pillar in the selection prompt.

## Impact
- **User Experience**: clearer visibility into content needs; reduced cognitive load when deciding what content to generate.
- **Affected Code**: `lib/tui/views/ai_prompts_view.rb`.
- **Dependencies**: Adds a dependency on `ContentPillars::GapAnalyzer` (from `packs/content_pillars`) in the TUI view.

## Risks / Trade-offs
- **Performance**: `GapAnalyzer` might take a moment to run. However, since this is an interactive TUI and the dataset size is likely manageable, the delay should be negligible.
- **Coupling**: TUI becomes slightly more coupled to `ContentPillars` logic, but this is intentional for a unified workflow.
