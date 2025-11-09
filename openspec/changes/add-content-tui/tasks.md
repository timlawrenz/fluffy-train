# Tasks: Content TUI

**Change ID**: `add-content-tui`  
**Status**: Proposal  
**Created**: 2025-11-09

---

## Phase 1: Setup & Dependencies (Day 1, ~2 hours)

### Dependencies

- [ ] Add TTY gems to Gemfile
  - [ ] `tty-prompt` ~> 0.23
  - [ ] `tty-table` ~> 0.12
  - [ ] `tty-box` ~> 0.7
  - [ ] `tty-pager` ~> 0.14
  - [ ] `tty-spinner` ~> 0.9
  - [ ] `tty-progressbar` ~> 0.18
  - [ ] `tty-screen` ~> 0.8
  - [ ] `pastel` ~> 0.8
  - [ ] `tty-cursor` ~> 0.7
- [ ] Run `bundle install`
- [ ] Verify gems installed correctly

### File Structure

- [ ] Create `lib/tui/` directory
- [ ] Create `lib/tui/application.rb` (main controller)
- [ ] Create `lib/tui/views/` directory
- [ ] Create `lib/tui/components/` directory
- [ ] Create `lib/tui/helpers/` directory
- [ ] Create `bin/fluffy-tui` executable
- [ ] Make `bin/fluffy-tui` executable (`chmod +x`)

---

## Phase 2: Core Application Framework (Day 1, ~4 hours)

### Main Application

- [ ] Create `TUI::Application` class
  - [ ] Accept `persona:` parameter in initialize
  - [ ] Create TTY::Prompt instance
  - [ ] Implement `run` method with main loop
  - [ ] Implement `main_menu` with 6 options
  - [ ] Implement `handle_choice` router
  - [ ] Add graceful exit on 'q' or Ctrl-C

### Executable Script

- [ ] Create `bin/fluffy-tui` script
  - [ ] Require Rails environment
  - [ ] Parse persona argument (default: 'sarah')
  - [ ] Find persona in database
  - [ ] Error handling if persona not found
  - [ ] Launch `TUI::Application`

### Base View Class

- [ ] Create `TUI::Views::BaseView`
  - [ ] Accept `persona:` parameter
  - [ ] Provide access to TTY::Prompt
  - [ ] Helper method for back/quit
  - [ ] Common header/footer rendering
  - [ ] Color scheme helpers

### Testing

- [ ] Manual test: Launch TUI
- [ ] Manual test: Navigate menu with arrows
- [ ] Manual test: Quit with 'q'
- [ ] Manual test: Works with sarah persona

---

## Phase 3: Dashboard View (Day 1-2, ~4 hours)

### Dashboard Implementation

- [ ] Create `TUI::Views::DashboardView`
  - [ ] Extend `BaseView`
  - [ ] Fetch scheduled posts (overdue/future)
  - [ ] Fetch active pillars
  - [ ] Run gap analysis
  - [ ] Build next actions list

### Dashboard Display

- [ ] Render scheduled posts section
  - [ ] Separate overdue vs future
  - [ ] Show count and details
  - [ ] Color-code status
- [ ] Render pillars section
  - [ ] Show pillar attributes
  - [ ] Inline gap analysis
  - [ ] Status icons
- [ ] Render next actions section
  - [ ] Priority indicators
  - [ ] Action descriptions
  - [ ] Hotkey hints

### Keyboard Shortcuts

- [ ] Implement 'u' → jump to cleanup
- [ ] Implement 'c' → jump to cluster assignment
- [ ] Implement 's' → jump to schedule
- [ ] Implement 'p' → jump to publish
- [ ] Implement 'q' → return to menu

### Testing

- [ ] Test with Sarah data
- [ ] Test with overdue posts
- [ ] Test with no posts
- [ ] Test all keyboard shortcuts

---

## Phase 4: Photo Browser (Day 2, ~6 hours)

### Image Display Helper

- [ ] Create `TUI::Helpers::ImageHelper`
  - [ ] Terminal detection (iTerm2/Kitty)
  - [ ] Inline image display (iTerm2/Kitty)
  - [ ] ASCII art fallback (catimg)
  - [ ] Thumbnail size configuration

### Photo Grid Component

- [ ] Create `TUI::Components::PhotoGrid`
  - [ ] Grid layout (5 per row)
  - [ ] Display thumbnails
  - [ ] Show filename below each
  - [ ] Mark posted vs unposted
  - [ ] Arrow key navigation
  - [ ] Selected photo highlighting

### Photo Browser View

- [ ] Create `TUI::Views::PhotoBrowserView`
  - [ ] Select cluster/pillar filter
  - [ ] Fetch photos
  - [ ] Render photo grid
  - [ ] Show selected photo metadata
  - [ ] Action menu (open, schedule, filter)

### Actions

- [ ] Implement 'o' → open full-size
  - [ ] Detect OS (macOS/Linux)
  - [ ] Open with default viewer (open/xdg-open)
- [ ] Implement 'f' → filter unposted
  - [ ] Re-render grid with only unposted
- [ ] Implement 's' → schedule selected photo
  - [ ] Jump to schedule view with photo pre-selected

### Testing

- [ ] Test in iTerm2 (inline images)
- [ ] Test in standard terminal (ASCII art)
- [ ] Test photo navigation
- [ ] Test open full-size
- [ ] Test filter unposted

---

## Phase 5: Schedule Post Workflow (Day 2-3, ~4 hours)

### Schedule View

- [ ] Create `TUI::Views::ScheduleView`
  - [ ] Call `ContentStrategy::SelectNextPost`
  - [ ] Extract photo, cluster, pillar, caption, hashtags
  - [ ] Calculate optimal time

### Post Preview Component

- [ ] Create `TUI::Components::PostPreview`
  - [ ] Display photo thumbnail
  - [ ] Show pillar/cluster info
  - [ ] Render caption
  - [ ] Render hashtags
  - [ ] Show optimal time

### Caption Editing

- [ ] Implement 'e' → edit caption
  - [ ] Detect $EDITOR environment variable
  - [ ] Write caption to temp file
  - [ ] Open in editor
  - [ ] Read edited caption back
  - [ ] Update preview

### Confirmation & Scheduling

- [ ] Implement 's' → confirm schedule
  - [ ] Create `Scheduling::Post` record
  - [ ] Set status, time, caption, hashtags
  - [ ] Save to database
  - [ ] Show success message
  - [ ] Return to menu
- [ ] Implement 'c' → cancel
  - [ ] Return to menu without scheduling

### Testing

- [ ] Test full schedule workflow
- [ ] Test caption editing
- [ ] Test cancel
- [ ] Verify post saved correctly

---

## Phase 6: Publish & Cleanup (Day 3, ~4 hours)

### Publish Pending View

- [ ] Create `TUI::Views::PublishView`
  - [ ] Fetch posts with status 'scheduled' or 'pending'
  - [ ] Multi-select list with checkboxes
  - [ ] Confirmation prompt

### Publish Workflow

- [ ] Implement multi-select
  - [ ] Spacebar toggles selection
  - [ ] Visual feedback (☐/☑)
- [ ] Implement publish action
  - [ ] Progress bar for publishing
  - [ ] Call `Scheduling::PublishPost` for each
  - [ ] Handle errors per post
  - [ ] Show success/error summary

### Cleanup Overdue View

- [ ] Create `TUI::Views::CleanupView`
  - [ ] Fetch overdue posts (optimal_time < now)
  - [ ] Show days overdue
  - [ ] Multi-select list

### Cleanup Actions

- [ ] Implement 'f' → mark failed
  - [ ] Update selected posts status to 'failed'
  - [ ] Confirmation before action
  - [ ] Success message
- [ ] Implement 'r' → reschedule
  - [ ] Prompt for new date/time
  - [ ] Update optimal_time
  - [ ] Success message

### Testing

- [ ] Test publish workflow
- [ ] Test multi-select
- [ ] Test publish errors
- [ ] Test cleanup workflow
- [ ] Test mark as failed

---

## Phase 7: Pillars & Clusters Browser (Day 3, ~4 hours)

### Tree Component

- [ ] Create `TUI::Components::PillarTree`
  - [ ] Hierarchical data structure
  - [ ] Expand/collapse state tracking
  - [ ] Render with indentation
  - [ ] Expand/collapse indicators (▶/▼)

### Pillars View

- [ ] Create `TUI::Views::PillarsView`
  - [ ] Fetch persona pillars
  - [ ] Fetch clusters per pillar
  - [ ] Build tree structure
  - [ ] Render tree with navigation

### Tree Navigation

- [ ] Implement ↑↓ navigation
- [ ] Implement Enter → expand/collapse
- [ ] Implement Enter on cluster → photo browser
- [ ] Show selected item highlighting

### Quick Actions

- [ ] Implement 'a' → assign cluster
  - [ ] Prompt to select cluster from list
  - [ ] Create `PillarClusterAssignment`
  - [ ] Refresh tree view
- [ ] Implement 'r' → remove cluster
  - [ ] Confirmation prompt
  - [ ] Destroy assignment
  - [ ] Refresh tree view

### Shared Cluster Indicators

- [ ] Detect clusters assigned to multiple pillars
- [ ] Show [SHARED: PillarName] label
- [ ] Mark primary assignments with ★

### Testing

- [ ] Test tree expansion
- [ ] Test navigation
- [ ] Test assign cluster
- [ ] Test remove cluster
- [ ] Test shared cluster display

---

## Phase 8: Polish & Error Handling (Day 4, ~4 hours)

### Color Scheme

- [ ] Create `TUI::Helpers::ColorHelper`
  - [ ] Define consistent color palette
  - [ ] Status colors (error, warning, success, info)
  - [ ] UI element colors (selected, inactive)
  - [ ] Helper methods for coloring text

### Help System

- [ ] Implement '?' → show help
  - [ ] Context-specific help text
  - [ ] Keyboard shortcuts cheat sheet
  - [ ] Example usage

### Error Handling

- [ ] Graceful API error handling
  - [ ] Catch exceptions
  - [ ] Show user-friendly message
  - [ ] Offer retry option
  - [ ] Log error details
- [ ] Empty state handling
  - [ ] No photos available
  - [ ] No pillars defined
  - [ ] No posts to publish
  - [ ] Actionable guidance

### Loading Indicators

- [ ] Spinner for slow operations
  - [ ] Fetching photos
  - [ ] Running gap analysis
  - [ ] Publishing posts
- [ ] Progress bars for batch operations

### Consistent UI Elements

- [ ] Standardize header format
- [ ] Standardize footer format
- [ ] Consistent action menu format
- [ ] Consistent error message format

### Testing

- [ ] Test error scenarios
- [ ] Test empty states
- [ ] Test help system
- [ ] Test loading indicators
- [ ] End-to-end workflow testing

---

## Phase 9: Documentation (Day 4, ~2 hours)

### User Documentation

- [ ] Create `docs/guides/tui-user-guide.md`
  - [ ] Installation instructions
  - [ ] Launch command
  - [ ] Feature overview
  - [ ] Keyboard shortcuts reference
  - [ ] Screenshot examples (ASCII art)

### Developer Documentation

- [ ] Update README.md with TUI section
- [ ] Document TUI architecture
  - [ ] File structure
  - [ ] Component responsibilities
  - [ ] Adding new views
- [ ] Code comments for complex logic

### Examples

- [ ] Example: Custom view creation
- [ ] Example: Adding keyboard shortcuts
- [ ] Example: Terminal image detection

---

## Phase 10: Testing & Validation (Day 4, ~2 hours)

### Manual Testing

- [ ] End-to-end workflow: Schedule post from launch to menu
- [ ] Test all keyboard shortcuts
- [ ] Test in iTerm2 terminal
- [ ] Test in standard terminal
- [ ] Test on macOS
- [ ] Test on Linux (if available)

### Edge Cases

- [ ] Empty database (no photos)
- [ ] Empty persona (no pillars/clusters)
- [ ] Network errors during publish
- [ ] Invalid $EDITOR variable
- [ ] Terminal too small (< 80x24)

### Performance

- [ ] Test with 100+ photos
- [ ] Test with 10+ pillars
- [ ] Test with 50+ scheduled posts
- [ ] Ensure < 2 second load time for any view

### Acceptance Testing

- [ ] Can launch TUI
- [ ] Can navigate all screens
- [ ] Can schedule post in < 30 seconds
- [ ] Can publish posts
- [ ] Can clean up overdue posts
- [ ] Images display correctly
- [ ] Errors handled gracefully

---

## Summary

**Total Estimated Time**: 4 days (~32 hours)

- Phase 1: Setup (2 hours)
- Phase 2: Core Framework (4 hours)
- Phase 3: Dashboard (4 hours)
- Phase 4: Photo Browser (6 hours)
- Phase 5: Schedule Workflow (4 hours)
- Phase 6: Publish & Cleanup (4 hours)
- Phase 7: Pillars Browser (4 hours)
- Phase 8: Polish (4 hours)
- Phase 9: Documentation (2 hours)
- Phase 10: Testing (2 hours)

**Total Tasks**: 150+ individual tasks  
**Critical Path**: Phases 1-5 (core workflow)  
**Nice-to-Have**: Phases 6-8 (enhanced features)  
**Essential**: Phase 10 (testing)
