# content-pillars Specification

## Purpose
TBD - created by archiving change add-content-pillar-system. Update Purpose after archive.
## Requirements
### Requirement: Pillar Definition and Management

System SHALL allow creation and management of content pillars with strategic attributes.

**Acceptance Criteria:**
- Pillar has name, description, weight (%), active status
- Pillar can have optional date range (start_date, end_date)
- Pillar stores guidelines (tone, topics, avoid_topics, style_notes) in JSONB
- Pillar belongs to exactly one persona
- Can create, read, update, deactivate (soft delete) pillars
- Weight validation: all active pillar weights sum to ≤100% per persona

#### Scenario: Create Thanksgiving pillar

- **GIVEN** Sarah persona exists  
- **WHEN** I create a pillar with name "Thanksgiving 2024", weight 30%, dates Nov 7-Dec 5  
- **THEN** pillar is created with strategic attributes  
- **AND** pillar.weight == 30.0  
- **AND** pillar.guidelines includes tone and topics

#### Scenario: Weight validation

- **GIVEN** Sarah has existing pillars totaling 80% weight  
- **WHEN** I try to create pillar with weight 25%  
- **THEN** validation fails (total would exceed 100%)  
- **AND** error message indicates weight limit exceeded

---

### Requirement: Many-to-Many Pillar-Cluster Relationships

System SHALL support many-to-many relationships between pillars and clusters through a join table, allowing clusters to serve multiple strategic purposes.

**Acceptance Criteria:**
- PillarClusterAssignment join model with pillar_id and cluster_id
- One cluster can belong to multiple pillars
- One pillar can have multiple clusters
- Assignment can be marked as "primary" (cluster's main pillar)
- Can query: pillar.clusters, cluster.pillars
- FK constraints prevent orphaned assignments

#### Scenario: Assign cluster to multiple pillars

- **GIVEN** "Cozy Home Moments" cluster exists  
- **AND** "Thanksgiving 2024" pillar exists  
- **AND** "Wellness & Self-Care" pillar exists  
- **WHEN** I assign cluster to Thanksgiving pillar  
- **AND** I assign cluster to Wellness pillar  
- **THEN** cluster.pillars.count == 2  
- **AND** both pillars list the cluster

#### Scenario: Mark primary pillar assignment

- **GIVEN** cluster assigned to multiple pillars  
- **WHEN** I mark Thanksgiving assignment as primary  
- **THEN** cluster.primary_pillar == Thanksgiving pillar

---

### Requirement: Content Gap Analysis

System SHALL analyze content gaps by comparing pillar target posts against available photos, and SHALL recommend content creation when gaps are identified.

**Acceptance Criteria:**
- Calculate posts_needed per pillar based on weight and timeframe
- Count available (unposted) photos across pillar's clusters
- Identify gap = posts_needed - photos_available
- Return status: :ready, :low, :critical, :exhausted
- Support configurable lookahead period (default 30 days)
- Recommend AI prompt generation for critical gaps

#### Scenario: Identify critical content gap and recommend creation

- **GIVEN** Thanksgiving pillar with weight 30%
- **AND** 30 total posts needed in next 30 days
- **AND** Thanksgiving target is 9 posts (30% of 30)
- **AND** 0 photos available in pillar's clusters
- **WHEN** running gap analysis
- **THEN** gap SHALL be 9
- **AND** status SHALL be :exhausted
- **AND** priority SHALL be :high
- **AND** system SHALL recommend AI prompt generation

#### Scenario: Gap filled through AI-suggested content creation

- **GIVEN** a pillar had a gap of 5 photos
- **AND** AI prompts were generated and clusters created
- **AND** 6 photos were generated and imported to clusters
- **WHEN** running gap analysis again
- **THEN** gap SHALL be -1 (surplus)
- **AND** status SHALL be :ready
- **AND** no content creation SHALL be recommended

### Requirement: Pillar-Aware Content Selection

Content strategy SHALL respect pillar weights when selecting next post, ensuring balanced coverage across strategic themes.

**Acceptance Criteria:**
- Strategy selects pillar based on weighted rotation algorithm
- Pillar selection accounts for posting history (underposted pillars prioritized)
- Photo selection limited to clusters assigned to selected pillar
- Caption/hashtag generation considers pillar guidelines
- Posting history records which pillar was used

#### Scenario: Select from underposted pillar

- **GIVEN** Thanksgiving pillar (30% weight) has posted 2/9 posts (22%)  
- **AND** Urban pillar (25% weight) has posted 3/8 posts (37%)  
- **WHEN** strategy selects next post  
- **THEN** Thanksgiving pillar is selected (most behind target)  
- **AND** photo is from Thanksgiving pillar's clusters  
- **AND** caption uses Thanksgiving guidelines (grateful tone)

#### Scenario: Exclude expired pillar

- **GIVEN** Thanksgiving pillar with end_date Dec 5, 2024  
- **AND** Current date is Dec 10, 2024  
- **WHEN** strategy selects next pillar  
- **THEN** Thanksgiving pillar is not considered  
- **AND** next active pillar is selected

---

### Requirement: Dashboard Pillar Visualization

Dashboard SHALL display content pillar hierarchy, showing pillars → clusters → photos with gap analysis.

**Acceptance Criteria:**
- Shows all active pillars for persona
- Displays pillar weight, date range, target posts
- Lists clusters assigned to each pillar
- Shows photo counts (total, unposted) per cluster
- Indicates gap status (🔴 critical, ⚠️ low, ✅ ready)

#### Scenario: Display pillar hierarchy

- **GIVEN** Thanksgiving pillar with 3 assigned clusters  
- **AND** Each cluster has photos  
- **WHEN** I view dashboard  
- **THEN** I see "Thanksgiving 2024 (30%, Nov 7-Dec 5)"  
- **AND** I see "Target: 9 posts | Available: 5 photos | Gap: 4"  
- **AND** I see list of 3 clusters with photo counts  
- **AND** I see action: "Need 4 more photos"

---

### Requirement: Pillar Management CLI

System SHALL provide CLI commands for pillar lifecycle management.

**Acceptance Criteria:**
- Create pillar: `rails pillars:create`
- List pillars: `rails pillars:list`
- Show pillar details: `rails pillars:show`
- Assign cluster: `rails pillars:assign_cluster`
- Gap analysis: `rails pillars:gaps`

#### Scenario: Create pillar via CLI

- **GIVEN** Sarah persona exists  
- **WHEN** I run `rails pillars:create PERSONA=sarah NAME="Thanksgiving 2024" WEIGHT=30`  
- **THEN** pillar is created  
- **AND** output confirms creation with pillar ID  
- **AND** `rails pillars:list` shows the new pillar

---

### Requirement: AI-Powered Content Gap Recommendations

The system SHALL generate AI-powered content creation prompts for pillars with identified content gaps.

#### Scenario: Generate AI prompts for pillar with gap

- **GIVEN** a pillar has a content gap of 5 photos
- **WHEN** requesting AI recommendations for the pillar
- **THEN** the system SHALL generate detailed image prompts
- **AND** prompts SHALL include scene, outfit, mood, and photography style
- **AND** prompts SHALL align with pillar theme and persona aesthetic
- **AND** prompts SHALL be suitable for AI image generation tools

#### Scenario: Create clusters from AI prompts

- **GIVEN** AI has generated 3 content prompts for a pillar
- **WHEN** creating clusters from the prompts
- **THEN** 3 clusters SHALL be created with ai_prompt field populated
- **AND** clusters SHALL be automatically linked to the pillar
- **AND** cluster names SHALL reflect the prompt's scene/theme
- **AND** clusters SHALL be empty, ready for photo import

#### Scenario: Save AI prompts for reference

- **GIVEN** AI prompts have been generated
- **WHEN** user chooses to save prompts
- **THEN** prompts SHALL be saved to markdown files
- **AND** files SHALL be organized by persona and pillar
- **AND** files SHALL include full prompt and structured metadata

---

### Requirement: Gap Analysis Integration with Content Creation

The system SHALL integrate gap analysis with AI-powered content recommendations to support proactive content planning.

#### Scenario: Detect gap and offer AI suggestions

- **GIVEN** gap analysis identifies a critical gap (>5 photos needed)
- **WHEN** viewing the gap analysis results
- **THEN** the system SHALL offer to generate AI content prompts
- **AND** user can trigger prompt generation directly from gap view
- **AND** generated prompts SHALL create clusters linked to the pillar

#### Scenario: Track AI-generated vs manual clusters

- **GIVEN** a pillar has both AI-generated and manual clusters
- **WHEN** querying the pillar's clusters
- **THEN** clusters with ai_prompt field SHALL be identifiable
- **AND** the system can differentiate between creation methods
- **AND** both types function identically in content selection

---

