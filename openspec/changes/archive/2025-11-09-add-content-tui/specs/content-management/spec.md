# Content TUI Specification Delta

**Change ID**: `add-content-tui`  
**Affects**: New capability

---

## ADDED Requirements

### TUI-1: Terminal User Interface Application

**Summary**: Provide an interactive terminal-based user interface for managing persona content workflow.

**Details**:
- Launch via `fluffy-tui [persona_name]` (defaults to 'sarah')
- Keyboard-driven navigation (no mouse required)
- Main menu with 6 core functions: Dashboard, Pillars, Photos, Schedule, Publish, Cleanup
- Graceful exit with 'q' or Esc
- Works in any ANSI-compatible terminal

**Acceptance Criteria**:
- User can launch TUI with `fluffy-tui sarah`
- Main menu displays with selectable options
- Navigation works with arrow keys and Enter
- 'q' quits at any screen level
- Returns to menu after each action

#### Scenario: Launch TUI for Sarah

**Given** Sarah persona exists in database  
**When** user runs `fluffy-tui sarah`  
**Then** TUI displays main menu with 6 options  
**And** user can navigate with arrow keys  
**And** pressing 'q' exits gracefully

---

### TUI-2: Dashboard View

**Summary**: Display persona content status, pillars, gaps, and actionable items in interactive format.

**Details**:
- Port `content_strategy:dashboard` output to interactive TUI
- Show: scheduled posts (overdue + future), active pillars with gaps, next 3 actions
- Keyboard shortcuts: 'u' cleanup, 'c' assign clusters, 's' schedule, 'p' publish
- Color-coded status: 🚫 exhausted, 🔴 critical, ⚠️ low, ✅ ready
- Read-only view with quick action hotkeys

**Acceptance Criteria**:
- Dashboard displays scheduled posts separated (overdue vs future)
- Shows active pillars with gap analysis inline
- Displays next 3 actionable items with priorities
- Hotkeys jump to relevant actions
- Refreshes data when returning to dashboard

#### Scenario: View Sarah's Dashboard

**Given** Sarah has 5 overdue posts and 2 active pillars  
**When** user selects "Dashboard" from main menu  
**Then** TUI displays overdue posts section with count  
**And** displays pillar section with gap analysis  
**And** displays next actions with hotkey hints  
**And** user can press 'u' to jump to cleanup  

---

### TUI-3: Photo Browser with Thumbnails

**Summary**: Browse photos by cluster/pillar with visual thumbnails in terminal.

**Details**:
- Grid layout showing photo thumbnails
- Auto-detect terminal: iTerm2/Kitty = inline images, others = ASCII art
- Show metadata: filename, status (posted/unposted), cluster, size, date
- Navigate with arrow keys, 'o' opens full-size in external viewer
- Filter: 'f' shows only unposted photos
- Select photo and press 's' to schedule

**Acceptance Criteria**:
- Grid displays up to 5 photos per row
- Inline images work in iTerm2/Kitty terminals
- ASCII art thumbnails work in other terminals
- Posted vs unposted status clearly marked
- Filter shows only unposted photos
- Selected photo highlighted
- 'o' opens full-resolution in default image viewer

#### Scenario: Browse Photos in iTerm2

**Given** user has iTerm2 terminal  
**And** cluster "Morning Coffee" has 8 photos (5 unposted, 3 posted)  
**When** user selects cluster from browser  
**Then** TUI displays 8 thumbnail images inline  
**And** posted photos marked with "Posted" label  
**And** unposted photos marked with "Unposted" label  
**When** user presses 'f' to filter  
**Then** only 5 unposted photos display  

#### Scenario: Browse Photos in Standard Terminal

**Given** user has standard terminal (not iTerm2/Kitty)  
**When** user browses photos  
**Then** TUI displays ASCII art thumbnails  
**And** thumbnails are recognizable representations  
**And** all other functionality works identically  

---

### TUI-4: Pillars & Clusters Tree Browser

**Summary**: Navigate pillar → cluster hierarchy with expand/collapse tree view.

**Details**:
- Tree structure: Pillars (collapsible) → Clusters → Photo counts
- Show pillar attributes: weight %, priority, date range
- Show cluster stats: total photos, unposted count
- Status icons: 🚫 exhausted, ⚠️ low, ✅ ready
- Actions: 'a' assign cluster to pillar, 'r' remove, Enter to view photos
- [SHARED] indicator for multi-pillar clusters

**Acceptance Criteria**:
- Pillars display with expand/collapse (▶/▼ indicators)
- Enter key toggles expansion
- Cluster stats show total and unposted counts
- Shared clusters marked with [SHARED: PillarName]
- Quick actions work without leaving view
- Navigate with arrow keys

#### Scenario: Expand Pillar to See Clusters

**Given** "Thanksgiving 2024" pillar has 3 assigned clusters  
**When** user navigates to pillar in tree view  
**And** presses Enter to expand  
**Then** 3 clusters display indented under pillar  
**And** each cluster shows photo count (X total, Y unposted)  
**When** user presses Enter on cluster  
**Then** photo browser opens for that cluster  

#### Scenario: Assign Cluster to Pillar

**Given** pillar "Urban Lifestyle" has no clusters  
**And** cluster "City Street Style" exists  
**When** user navigates to pillar  
**And** presses 'a' for assign  
**Then** TUI prompts to select cluster  
**When** user selects "City Street Style"  
**Then** cluster assigned to pillar  
**And** tree view updates to show cluster under pillar  

---

### TUI-5: Schedule Post Workflow

**Summary**: Interactive post scheduling with preview and confirmation.

**Details**:
- Calls `ContentStrategy::SelectNextPost` service
- Displays: selected pillar, cluster, photo thumbnail
- Shows generated caption and hashtags
- Displays optimal posting time
- Actions: 's' confirm schedule, 'e' edit caption, 'c' cancel
- Edit caption opens $EDITOR (vim/nano/etc)

**Acceptance Criteria**:
- Service selects pillar/cluster/photo automatically
- Photo preview displays (inline or ASCII)
- Caption and hashtags shown
- Optimal time calculated and displayed
- 's' schedules post and returns to menu
- 'e' opens editor, saves changes, schedules
- 'c' cancels and returns without scheduling

#### Scenario: Schedule Next Post Successfully

**Given** Sarah has unposted photos available  
**When** user selects "Schedule Post"  
**Then** TUI calls SelectNextPost service  
**And** displays selected pillar name  
**And** displays selected cluster name  
**And** displays photo thumbnail  
**And** displays generated caption  
**And** displays hashtags  
**And** displays optimal posting time  
**When** user presses 's' to confirm  
**Then** post scheduled in database  
**And** success message displays  
**And** returns to main menu  

#### Scenario: Edit Caption Before Scheduling

**Given** scheduling workflow shows generated caption  
**When** user presses 'e' to edit  
**Then** $EDITOR opens with caption text  
**When** user edits and saves in editor  
**Then** TUI shows updated caption  
**When** user presses 's' to schedule  
**Then** post scheduled with edited caption  

---

### TUI-6: Publish Pending Posts

**Summary**: Select and publish scheduled posts ready to go live.

**Details**:
- List all posts with status 'scheduled' or 'pending'
- Multi-select with spacebar
- Show post time, caption preview, photo filename
- Confirm selection before publishing
- Progress bar during publish operation
- Handle errors gracefully (show which failed)

**Acceptance Criteria**:
- All pending posts display in list
- Spacebar toggles selection (☐/☑)
- Enter confirms selection
- Progress bar shows during publish
- Success/error status for each post
- Returns to menu when complete

#### Scenario: Publish Multiple Posts

**Given** 3 posts are pending publication  
**When** user selects "Publish Pending"  
**Then** TUI displays list of 3 posts  
**When** user presses Space on first post  
**Then** checkbox toggles to ☑  
**When** user presses Space on third post  
**Then** checkbox toggles to ☑  
**When** user presses Enter  
**Then** confirmation prompt displays  
**When** user confirms  
**Then** progress bar shows "Publishing 2 posts..."  
**And** each post publishes to Instagram  
**And** success message shows count  

---

### TUI-7: Cleanup Overdue Posts

**Summary**: Mark overdue posts as failed to clean up pipeline.

**Details**:
- List all posts where optimal_time < now
- Show days overdue for each post
- Multi-select which posts to mark as failed
- Option to reschedule instead of mark failed
- Confirmation before bulk action

**Acceptance Criteria**:
- Only overdue posts display
- Shows days overdue for each
- Multi-select with spacebar
- Actions: 'f' mark failed, 'r' reschedule selected
- Confirmation required before action
- Updates post status in database

#### Scenario: Mark Overdue Posts as Failed

**Given** 5 posts are overdue by 4-5 days  
**When** user selects "Cleanup Overdue"  
**Then** TUI lists 5 overdue posts with days overdue  
**When** user selects 3 posts with spacebar  
**And** presses 'f' to mark failed  
**Then** confirmation prompt displays  
**When** user confirms  
**Then** 3 posts marked as status 'failed'  
**And** success message shows  
**And** returns to main menu  

---

### TUI-8: Image Display Support

**Summary**: Display photo thumbnails in terminal with fallback support.

**Details**:
- Auto-detect terminal capabilities
- iTerm2/Kitty: Inline images via imgcat protocol
- Other terminals: ASCII/Unicode art via catimg
- Configurable thumbnail size (default 24x16 chars)
- Cache ASCII art to avoid regeneration

**Acceptance Criteria**:
- Detection identifies iTerm2 via $TERM_PROGRAM
- Detection identifies Kitty via $TERM
- Inline images render correctly in supported terminals
- ASCII art readable in non-supported terminals
- Fallback graceful if image libraries missing

#### Scenario: Display Image in iTerm2

**Given** user runs TUI in iTerm2 terminal  
**When** photo thumbnail needs to display  
**Then** TUI detects iTerm2 via environment variable  
**And** displays inline image using imgcat protocol  
**And** image renders at 24x16 character size  

#### Scenario: Display Image in Standard Terminal

**Given** user runs TUI in standard terminal  
**When** photo thumbnail needs to display  
**Then** TUI detects non-supported terminal  
**And** converts image to ASCII art  
**And** displays ASCII representation  
**And** image is recognizable  

---

### TUI-9: Navigation & Keyboard Controls

**Summary**: Consistent keyboard navigation across all TUI screens.

**Details**:
- Arrow keys: ↑↓ navigate, ←→ navigate in grids
- Enter: Select/confirm
- Space: Toggle (in multi-select)
- q: Quit/back to previous screen
- ?: Show help/keyboard shortcuts
- Letters: Quick actions (context-specific)

**Acceptance Criteria**:
- Arrow key navigation works consistently
- 'q' goes back or quits from main menu
- '?' displays context help
- No conflicting keybindings
- Clear indication of available actions

#### Scenario: Navigate Dashboard with Keyboard

**Given** user viewing dashboard  
**When** user presses '?'  
**Then** help overlay shows available commands  
**And** shows: u=cleanup, c=clusters, s=schedule, p=publish, q=quit  
**When** user presses 'u'  
**Then** jumps to cleanup screen  
**When** user presses 'q'  
**Then** returns to dashboard  

---

### TUI-10: Error Handling & Feedback

**Summary**: Graceful error handling with clear user feedback.

**Details**:
- API errors: Show error message, allow retry
- Missing data: Show helpful message (e.g., "No unposted photos")
- Loading states: Spinner or progress indicator
- Success feedback: Confirmation message with details
- Validation errors: Highlight issue, allow correction

**Acceptance Criteria**:
- Network errors don't crash TUI
- Missing dependencies show installation hint
- Empty states show actionable guidance
- Success messages confirm actions
- Loading indicators show during slow operations

#### Scenario: Handle No Unposted Photos

**Given** all photos have been posted  
**When** user tries to schedule post  
**Then** TUI shows error message  
**And** message says "No unposted photos available"  
**And** suggests importing more photos  
**And** returns to menu without crashing  

#### Scenario: Handle Instagram API Error

**Given** Instagram API is down  
**When** user tries to publish post  
**Then** TUI shows error message  
**And** error includes API response  
**And** offers retry option  
**When** user retries  
**Then** attempts publish again  

---

## Dependencies

**New Gems Required**:
- `tty-prompt` ~> 0.23
- `tty-table` ~> 0.12
- `tty-box` ~> 0.7
- `tty-pager` ~> 0.14
- `tty-spinner` ~> 0.9
- `tty-progressbar` ~> 0.18
- `tty-screen` ~> 0.8
- `pastel` ~> 0.8
- `tty-cursor` ~> 0.7

**Optional Dependencies**:
- `catimg` (for ASCII art thumbnails)

**System Requirements**:
- Ruby 3.x
- ANSI-compatible terminal
- iTerm2/Kitty recommended for best experience

---

## Integration Points

**Existing Services**:
- `ContentStrategy::SelectNextPost` - Schedule workflow
- `Scheduling::PublishPost` - Publish workflow
- `ContentPillars::GapAnalyzer` - Gap analysis
- `ContentPillars::RotationService` - Pillar selection

**Existing Models**:
- `Persona` - Current persona context
- `ContentPillar` - Pillar data
- `Clustering::Cluster` - Cluster data
- `Photo` - Photo data and metadata
- `Scheduling::Post` - Post scheduling

**No New Database Changes Required**: TUI is pure view layer using existing data structures.

---

## Success Metrics

**Primary Metrics**:
- Time to schedule post: Target < 30 seconds (vs 2-3 minutes CLI)
- User adoption: Daily TUI usage vs CLI commands
- Error rate: < 5% failed operations

**Secondary Metrics**:
- Image preview usage rate
- Keyboard shortcut usage
- Feature discovery (which views used most)

---

## Notes

- TUI complements CLI, doesn't replace it
- Complex operations (create persona, import photos) stay in CLI
- Focus on Sarah's daily workflow first
- Can expand to other personas later
- Web GUI is separate future consideration
