# Implementation Proposal: Content Management TUI

## Why

**Current Problem:** Managing Sarah's content requires remembering and typing many CLI commands:

```bash
rails content_strategy:dashboard PERSONA=sarah
rails pillars:list PERSONA=sarah
rails pillars:show PILLAR_ID=2
rails pillars:assign_cluster PILLAR_ID=2 CLUSTER_ID=5
rails content_strategy:schedule_next PERSONA=sarah
rails scheduling:publish_pending
```

**Pain Points:**
1. **Cognitive Load**: Must remember exact command syntax and parameter names
2. **Context Switching**: Switch between terminal scrollback to find IDs, copy-paste values
3. **No Visual Hierarchy**: Text output, hard to scan/navigate large datasets
4. **Error-Prone**: Easy to typo PILLAR_ID or CLUSTER_ID
5. **Slow Workflow**: Type → wait → read → type next command
6. **Image Blindness**: Can't see photo thumbnails when selecting content

**Current Workflow to Schedule a Post:**
```
1. rails content_strategy:dashboard PERSONA=sarah
2. Read output, find pillar with gaps
3. rails pillars:show PILLAR_ID=X
4. See which clusters are assigned
5. rails clustering:photos CLUSTER_ID=Y
6. Pick photo by filename (blind - no preview)
7. rails content_strategy:schedule_next PERSONA=sarah
8. Hope it picked a good photo
```

**Desired Workflow (TUI):**
```
1. fluffy-tui sarah
2. Navigate with arrow keys through pillars/clusters
3. See photo thumbnails inline
4. Press 's' to schedule next post
5. Done!
```

---

## What Changes

This proposal adds a Terminal User Interface (TUI) built with TTY toolkit, focused on **Sarah's content workflow** - the critical path to get content posted.

### Scope: Sarah Content Workflow Only

**In Scope:**
- ✅ View dashboard (pillars, clusters, scheduled posts)
- ✅ Browse photos by cluster/pillar with thumbnails
- ✅ Schedule next post
- ✅ Publish pending posts
- ✅ Assign clusters to pillars
- ✅ Mark overdue posts as failed
- ✅ View gap analysis

**Out of Scope (CLI commands are fine for these):**
- ❌ Create new personas (rare, complex form)
- ❌ Import photos (bulk operation, CLI better)
- ❌ Generate clusters (long-running, CLI better)
- ❌ Gemini API configuration (one-time setup)
- ❌ Create pillars (complex form, CLI is OK)

---

## How It Works

### 1. Main Navigation

```
╔══════════════════════════════════════════════════════════════════╗
║  FLUFFY-TRAIN: Sarah Content Manager                             ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  📊 Dashboard                 View content status & gaps         ║
║  📚 Pillars & Clusters        Browse content organization        ║
║  📸 Photo Browser             Browse photos with thumbnails      ║
║  ⏰ Schedule Post             Schedule next post now             ║
║  🚀 Publish Pending           Publish scheduled posts            ║
║  🧹 Cleanup                   Mark overdue posts as failed       ║
║  ❌ Exit                                                          ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝

Use ↑↓ arrows to navigate, Enter to select, q to quit
```

### 2. Dashboard View (Read-Only)

Interactive version of `rails content_strategy:dashboard`:

```
╔══════════════════════════════════════════════════════════════════╗
║  📊 DASHBOARD: Sarah                                             ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  📅 SCHEDULED POSTS                                              ║
║  ────────────────────────────────────────────────────────────    ║
║  ❌ 5 OVERDUE posts                                              ║
║     Nov 4, 12:07 AM ET - sarah.a1_2025-01-09_00009_.png          ║
║     Nov 4, 12:18 AM ET - sarah.a1_2024-11-12_00045_.png          ║
║                                                                   ║
║  ✓ 0 posts scheduled ahead                                       ║
║                                                                   ║
║  📚 CONTENT PILLARS                                              ║
║  ────────────────────────────────────────────────────────────    ║
║  🚫 Urban Lifestyle (25% | Priority: 4/5)                        ║
║     Target: 4 posts | Available: 0 photos | Gap: 4              ║
║     → Press 'c' to assign clusters                               ║
║                                                                   ║
║  🎬 NEXT ACTIONS                                                 ║
║  ────────────────────────────────────────────────────────────    ║
║  1. 🔴 URGENT Clean up 5 overdue posts → Press 'u'              ║
║  2. 🔴 HIGH Create content for Urban Lifestyle                   ║
║  3. 🟡 MEDIUM Assign clusters to Urban Lifestyle → Press 'c'    ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝

Commands: [u] Cleanup [c] Assign Clusters [s] Schedule [p] Publish [q] Quit
```

**Keyboard Shortcuts:**
- `u` - Jump to cleanup overdue posts
- `c` - Jump to cluster assignment
- `s` - Schedule next post
- `p` - Publish pending posts
- `q` - Quit

### 3. Pillars & Clusters Browser

Interactive tree view with drill-down:

```
╔══════════════════════════════════════════════════════════════════╗
║  📚 PILLARS & CLUSTERS                                           ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  ▶ 🚫 Urban Lifestyle (25% | 0 photos available)                ║
║  ▼ ➖ Thanksgiving 2024 [EXPIRED] (30% | 17 photos)             ║
║       ✅ Morning Coffee Autumn (5 photos, 5 unposted)           ║
║       ⚠️  Neighborhood Spot (3 photos, 2 unposted)               ║
║       🚫 Cozy Home (4 photos, 0 unposted)                        ║
║  ▶ ✅ Wellness & Self-Care (20% | 12 photos)                    ║
║                                                                   ║
║  Selected: Thanksgiving 2024 > Morning Coffee Autumn            ║
║  Actions: [a] Assign cluster [r] Remove cluster [Enter] View    ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝

↑↓ Navigate | Enter: Expand/View | a: Assign | r: Remove | q: Back
```

**Features:**
- Tree view: Pillar → Clusters → Photos
- Expand/collapse with Enter
- See photo counts inline
- Quick actions: assign, remove clusters

### 4. Photo Browser (with Thumbnails)

Browse photos with inline terminal images:

```
╔══════════════════════════════════════════════════════════════════╗
║  📸 PHOTO BROWSER: Morning Coffee Autumn                         ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐        ║
║  │ [IMG1] │ │ [IMG2] │ │ [IMG3] │ │ [IMG4] │ │ [IMG5] │        ║
║  │  24x16 │ │  24x16 │ │  24x16 │ │  24x16 │ │  24x16 │        ║
║  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘        ║
║   Posted     Unposted   Unposted   Posted    Unposted           ║
║                                                                   ║
║  Selected: sarah.a1_2024-11-12_00045_.png                       ║
║  Status: Unposted | Cluster: Morning Coffee Autumn              ║
║  Size: 3024x4032 | Date: 2024-11-12                             ║
║                                                                   ║
║  Actions: [o] Open full-size [s] Schedule this photo [q] Back   ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝

←→ Navigate | o: Open | s: Schedule | f: Filter unposted | q: Back
```

**Image Display:**
- iTerm2/Kitty: Inline images (best)
- Other terminals: ASCII art thumbnails
- Filter: Show only unposted photos

### 5. Schedule Next Post (Interactive)

```
╔══════════════════════════════════════════════════════════════════╗
║  ⏰ SCHEDULE NEXT POST                                           ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  ✓ Selected pillar: Urban Lifestyle (via rotation)              ║
║  ✓ Selected cluster: City Street Style                          ║
║  ✓ Selected photo: sarah.a1_2024-11-15_00023_.png               ║
║                                                                   ║
║  ┌────────┐                                                      ║
║  │ [IMG]  │  Preview of selected photo                          ║
║  │ 32x24  │                                                      ║
║  └────────┘                                                      ║
║                                                                   ║
║  📝 Generated Caption:                                           ║
║  "City vibes: Casually chic in the heart of downtown."          ║
║                                                                   ║
║  #️⃣ Hashtags: #UrbanStyle #CityLife #DowntownVibes              ║
║                                                                   ║
║  ⏰ Optimal Time: Tomorrow, Nov 10, 2:30 PM ET                   ║
║                                                                   ║
║  ✓ [s] Schedule this post                                       ║
║  ✗ [c] Cancel and pick different photo                          ║
║  ✎ [e] Edit caption before scheduling                           ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

**Features:**
- Preview photo + caption + hashtags
- Edit caption inline (opens editor)
- Confirm before scheduling

### 6. Publish Pending

```
╔══════════════════════════════════════════════════════════════════╗
║  🚀 PUBLISH PENDING POSTS                                        ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Found 3 posts ready to publish:                                 ║
║                                                                   ║
║  ☐ Nov 10, 2:30 PM ET - City vibes...                           ║
║  ☐ Nov 11, 6:45 PM ET - Autumn sunset...                        ║
║  ☑ Nov 12, 11:15 AM ET - Coffee break...                        ║
║                                                                   ║
║  Select posts to publish (Space to toggle, Enter when done)     ║
║                                                                   ║
║  Publishing 1 post...                                            ║
║  ████████████░░░░░░░░ 60% Uploading to Instagram...             ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

### 7. Cleanup Overdue Posts

```
╔══════════════════════════════════════════════════════════════════╗
║  🧹 CLEANUP OVERDUE POSTS                                        ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Found 5 overdue posts:                                          ║
║                                                                   ║
║  ☑ Nov 4, 12:07 AM ET (5 days ago) - City vibes...              ║
║  ☑ Nov 4, 12:18 AM ET (5 days ago) - Channeling...              ║
║  ☐ Nov 4, 12:23 AM ET (5 days ago) - Breathing...               ║
║  ☐ Nov 4, 12:34 AM ET (5 days ago) - Casual chic...             ║
║  ☐ Nov 4, 12:55 AM ET (5 days ago) - Beach vibes...             ║
║                                                                   ║
║  Action: [f] Mark selected as failed [r] Reschedule [q] Cancel  ║
║                                                                   ║
║  ✓ Marked 2 posts as failed                                     ║
║                                                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## Technical Architecture

### 1. Dependencies

```ruby
# Gemfile
gem 'tty-prompt'      # Interactive prompts, menus, multi-select
gem 'tty-table'       # Beautiful ASCII tables
gem 'tty-box'         # Bordered content boxes
gem 'tty-pager'       # Scrollable content
gem 'tty-spinner'     # Loading indicators
gem 'tty-progressbar' # Progress bars
gem 'tty-screen'      # Terminal size detection
gem 'pastel'          # Color output
gem 'tty-cursor'      # Cursor manipulation

# Optional: Terminal image display
gem 'catimg'          # Convert images to ASCII/Unicode
```

### 2. File Structure

```
lib/tui/
├── fluffy_tui.rb              # Main entry point
├── application.rb             # TUI application controller
├── views/
│   ├── base_view.rb           # Base class for all views
│   ├── dashboard_view.rb      # Dashboard display
│   ├── pillars_view.rb        # Pillar/cluster browser
│   ├── photo_browser_view.rb  # Photo browsing with thumbnails
│   ├── schedule_view.rb       # Schedule post workflow
│   ├── publish_view.rb        # Publish pending posts
│   └── cleanup_view.rb        # Cleanup overdue posts
├── components/
│   ├── pillar_tree.rb         # Tree view component
│   ├── photo_grid.rb          # Photo grid with thumbnails
│   ├── post_preview.rb        # Post preview component
│   └── action_menu.rb         # Action menu component
└── helpers/
    ├── image_helper.rb        # Terminal image display
    ├── color_helper.rb        # Consistent color scheme
    └── format_helper.rb       # Text formatting utilities

bin/
└── fluffy-tui                 # Executable script
```

### 3. Entry Point

```ruby
#!/usr/bin/env ruby
# bin/fluffy-tui

require_relative '../config/environment'
require_relative '../lib/tui/application'

persona_name = ARGV[0] || 'sarah'
persona = Persona.find_by(name: persona_name)

unless persona
  puts "❌ Persona '#{persona_name}' not found"
  exit 1
end

TUI::Application.new(persona: persona).run
```

### 4. Main Application

```ruby
# lib/tui/application.rb
module TUI
  class Application
    def initialize(persona:)
      @persona = persona
      @prompt = TTY::Prompt.new
      @running = true
    end

    def run
      while @running
        choice = main_menu
        handle_choice(choice)
      end
    end

    private

    def main_menu
      @prompt.select("FLUFFY-TRAIN: #{@persona.name.titleize} Content Manager", per_page: 10) do |menu|
        menu.choice "📊 Dashboard", :dashboard
        menu.choice "📚 Pillars & Clusters", :pillars
        menu.choice "📸 Photo Browser", :photos
        menu.choice "⏰ Schedule Post", :schedule
        menu.choice "🚀 Publish Pending", :publish
        menu.choice "🧹 Cleanup Overdue", :cleanup
        menu.choice "❌ Exit", :exit
      end
    end

    def handle_choice(choice)
      case choice
      when :dashboard
        Views::DashboardView.new(persona: @persona).render
      when :pillars
        Views::PillarsView.new(persona: @persona).render
      when :photos
        Views::PhotoBrowserView.new(persona: @persona).render
      when :schedule
        Views::ScheduleView.new(persona: @persona).render
      when :publish
        Views::PublishView.new(persona: @persona).render
      when :cleanup
        Views::CleanupView.new(persona: @persona).render
      when :exit
        @running = false
      end
    end
  end
end
```

### 5. Image Display (Terminal Images)

```ruby
# lib/tui/helpers/image_helper.rb
module TUI
  module Helpers
    module ImageHelper
      def display_image(path, width: 24, height: 16)
        if iterm2_or_kitty?
          display_inline_image(path, width, height)
        else
          display_ascii_image(path, width, height)
        end
      end

      def iterm2_or_kitty?
        ENV['TERM_PROGRAM'] == 'iTerm.app' || ENV['TERM'] =~ /kitty/
      end

      def display_inline_image(path, width, height)
        # Use iTerm2 inline image protocol or Kitty graphics protocol
        # See: https://iterm2.com/documentation-images.html
        encoded = Base64.strict_encode64(File.read(path))
        print "\033]1337;File=inline=1;width=#{width};height=#{height}:#{encoded}\a"
      end

      def display_ascii_image(path, width, height)
        # Use catimg or similar to convert to ASCII/Unicode art
        system("catimg -w #{width} -h #{height} #{path}")
      end
    end
  end
end
```

---

## Implementation Plan

### Phase 1: Core TUI Framework (Day 1)
- [ ] Add TTY gem dependencies
- [ ] Create `lib/tui/` structure
- [ ] Create `bin/fluffy-tui` executable
- [ ] Build `TUI::Application` main menu
- [ ] Basic navigation working

### Phase 2: Dashboard View (Day 1)
- [ ] Port `content_strategy:dashboard` to TUI
- [ ] Display scheduled posts, pillars, actions
- [ ] Add keyboard shortcuts (u, c, s, p)
- [ ] Make it read-only for now

### Phase 3: Photo Browser (Day 2)
- [ ] Detect terminal type (iTerm2/Kitty vs others)
- [ ] Implement inline image display (iTerm2/Kitty)
- [ ] Implement ASCII thumbnail fallback
- [ ] Grid layout for photos
- [ ] Filter by cluster/pillar
- [ ] Show posted vs unposted status

### Phase 4: Schedule Post Workflow (Day 2)
- [ ] Interactive schedule view
- [ ] Call `ContentStrategy::SelectNextPost`
- [ ] Preview photo + caption + hashtags
- [ ] Edit caption inline
- [ ] Confirm and schedule

### Phase 5: Publish & Cleanup (Day 3)
- [ ] Multi-select pending posts
- [ ] Progress bar for publishing
- [ ] Multi-select overdue posts
- [ ] Mark as failed action

### Phase 6: Pillars & Clusters Browser (Day 3)
- [ ] Tree view component
- [ ] Expand/collapse pillars
- [ ] Quick assign/remove clusters
- [ ] Drill down to photos

### Phase 7: Polish (Day 4)
- [ ] Consistent color scheme
- [ ] Error handling
- [ ] Loading spinners
- [ ] Help text
- [ ] Keyboard shortcuts cheat sheet

---

## Success Criteria

**Must Have:**
- ✅ Launch with `fluffy-tui sarah`
- ✅ Navigate with keyboard only (no mouse needed)
- ✅ See photo thumbnails (ASCII or inline images)
- ✅ Schedule post in < 30 seconds
- ✅ Publish posts without leaving TUI
- ✅ Clean up overdue posts

**Nice to Have:**
- 🎯 Full-resolution image preview (opens in external viewer)
- 🎯 Search/filter photos
- 🎯 Bulk operations (schedule multiple posts)
- 🎯 Real-time updates (watch mode)

---

## Benefits

1. **10x Faster Workflow**: Navigate → Select → Schedule in seconds
2. **Visual Context**: See photo thumbnails, not just filenames
3. **No Context Switching**: Everything in one interface
4. **Fewer Errors**: Interactive selection, no ID typos
5. **Better UX**: Keyboard navigation feels native
6. **Terminal-Native**: Stays in your workflow (no browser needed)

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Terminal doesn't support inline images | Fallback to ASCII art (catimg) |
| Large datasets slow to render | Pagination with tty-pager |
| Complex forms needed (create pillar) | Keep those in CLI for now |
| Users prefer web GUI | Build TUI first, web GUI later (not exclusive) |

---

## Open Questions

1. **Image thumbnails**: ASCII art or require iTerm2/Kitty?
   - **Proposal**: Support both, auto-detect terminal
2. **Edit caption**: Inline or open $EDITOR?
   - **Proposal**: Open $EDITOR (vim/nano)
3. **Persona selection**: Hardcode Sarah or select from list?
   - **Proposal**: Command-line arg: `fluffy-tui sarah`

---

## Future Enhancements (Out of Scope)

- Web GUI (complementary, not replacement)
- Mobile TUI (termux support)
- Multi-persona dashboard
- Analytics/metrics view
- AI chat interface within TUI
- Bulk scheduling wizard

---

## Summary

Build a **Terminal User Interface** using TTY toolkit focused on **Sarah's content workflow**:

- Dashboard, photo browser, scheduler, publisher, cleanup
- Photo thumbnails (inline images or ASCII art)
- Keyboard-driven navigation
- 4-day implementation
- Complements (doesn't replace) CLI commands
- Faster workflow for day-to-day content management

**Key Insight**: TUI is the 80/20 solution - handles the most common workflows with minimal boilerplate, while complex/rare operations stay in CLI.
