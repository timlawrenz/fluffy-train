# tui Specification

## Purpose
TBD - created by archiving change enhance-pillar-tui-stats. Update Purpose after archive.
## Requirements
### Requirement: Pillar Recommendation
The TUI SHALL suggest which pillar to generate content for based on content strategy gaps.

#### Scenario: Suggestion provided
- **WHEN** the user selects "Generate cluster suggestions for a pillar"
- **THEN** the system analyzes content gaps
- **AND** suggests the pillar with the highest need (e.g., "Recommended: [Pillar Name]")

### Requirement: Pillar Selection List
The pillar selection list MUST display actionable metrics for each pillar.

#### Scenario: Show unposted photos
- **WHEN** the list of pillars is displayed
- **THEN** each entry shows the number of unposted photos
- **AND** optionally shows the total number of clusters

