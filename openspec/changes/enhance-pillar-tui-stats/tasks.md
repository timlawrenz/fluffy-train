## 1. Implementation
- [x] 1.1 Update `lib/tui/views/ai_prompts_view.rb` to calculate unposted photo counts using `Photo.unposted` scope.
- [x] 1.2 Update `lib/tui/views/ai_prompts_view.rb` to display unposted counts in the pillar list.
- [x] 1.3 Integrate `ContentPillars::GapAnalyzer` into `lib/tui/views/ai_prompts_view.rb` to find the recommended pillar.
- [x] 1.4 Update the pillar selection prompt to indicate the recommended pillar (e.g., via default selection or visual marker).
- [x] 1.5 Manually verify the TUI changes by running `bin/fluffy-tui`.