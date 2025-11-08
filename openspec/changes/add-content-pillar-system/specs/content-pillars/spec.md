# Capability Spec: Content Pillars

**Capability ID**: `content-pillars`  
**Version**: 1.0.0  
**Status**: Proposed  
**Owner**: Content Strategy Team

---

## Purpose

Enable strategic content organization through pillars (themes) that guide content creation, cluster assignment, and posting strategy. Pillars provide strategic coherence while clusters provide tactical organization.

---

## ADDED Requirements

### REQ-1: Pillar Definition and Management

**ID**: `PILLAR-001`  
**Priority**: High  
**Type**: Functional

**Description:**  
System shall allow creation and management of content pillars with strategic attributes.

**Acceptance Criteria:**
- Pillar has name, description, weight (%), active status
- Pillar can have optional date range (start_date, end_date)
- Pillar stores guidelines (tone, topics, avoid_topics, style_notes) in JSONB
- Pillar belongs to exactly one persona
- Can create, read, update, deactivate (soft delete) pillars
- Weight validation: all active pillar weights sum to ≤100% per persona

#### Scenario: Create Thanksgiving pillar

**Given** Sarah persona exists  
**When** I create a pillar with name "Thanksgiving 2024", weight 30%, dates Nov 7-Dec 5  
**Then** pillar is created with strategic attributes  
**And** pillar.weight == 30.0  
**And** pillar.guidelines includes tone and topics

#### Scenario: Weight validation

**Given** Sarah has existing pillars totaling 80% weight  
**When** I try to create pillar with weight 25%  
**Then** validation fails (total would exceed 100%)  
**And** error message indicates weight limit exceeded

---

### REQ-2: Many-to-Many Pillar-Cluster Relationships

**ID**: `PILLAR-002`  
**Priority**: High  
**Type**: Functional

**Description:**  
System shall support many-to-many relationships between pillars and clusters through a join table, allowing clusters to serve multiple strategic purposes.

**Acceptance Criteria:**
- PillarClusterAssignment join model with pillar_id and cluster_id
- One cluster can belong to multiple pillars
- One pillar can have multiple clusters
- Assignment can be marked as "primary" (cluster's main pillar)
- Can query: pillar.clusters, cluster.pillars
- FK constraints prevent orphaned assignments

#### Scenario: Assign cluster to multiple pillars

**Given** "Cozy Home Moments" cluster exists  
**And** "Thanksgiving 2024" pillar exists  
**And** "Wellness & Self-Care" pillar exists  
**When** I assign cluster to Thanksgiving pillar  
**And** I assign cluster to Wellness pillar  
**Then** cluster.pillars.count == 2  
**And** both pillars list the cluster

#### Scenario: Mark primary pillar assignment

**Given** cluster assigned to multiple pillars  
**When** I mark Thanksgiving assignment as primary  
**Then** cluster.primary_pillar == Thanksgiving pillar

---

### REQ-3: Content Gap Analysis

**ID**: `PILLAR-003`  
**Priority**: High  
**Type**: Functional

**Description:**  
System shall analyze content gaps by comparing pillar target posts against available photos.

**Acceptance Criteria:**
- Calculate posts_needed per pillar based on weight and timeframe
- Count available (unposted) photos across pillar's clusters
- Identify gap = posts_needed - photos_available
- Return status: :ready, :low, :critical
- Support configurable lookahead period (default 30 days)

#### Scenario: Identify critical content gap

**Given** Thanksgiving pillar with weight 30%  
**And** 30 total posts needed in next 30 days  
**And** Thanksgiving target is 9 posts (30% of 30)  
**And** 0 unposted photos in Thanksgiving clusters  
**When** I run gap analysis  
**Then** gap status is :critical  
**And** gap == 9  
**And** recommended action is "create 9 photos"

#### Scenario: Pillar ready to post

**Given** Urban Lifestyle pillar needs 8 posts  
**And** 15 unposted photos available  
**When** I run gap analysis  
**Then** status is :ready  
**And** gap == -7 (surplus)

---

### REQ-4: Pillar-Aware Content Selection

**ID**: `PILLAR-004`  
**Priority**: High  
**Type**: Functional

**Description:**  
Content strategy shall respect pillar weights when selecting next post, ensuring balanced coverage across strategic themes.

**Acceptance Criteria:**
- Strategy selects pillar based on weighted rotation algorithm
- Pillar selection accounts for posting history (underposted pillars prioritized)
- Photo selection limited to clusters assigned to selected pillar
- Caption/hashtag generation considers pillar guidelines
- Posting history records which pillar was used

#### Scenario: Select from underposted pillar

**Given** Thanksgiving pillar (30% weight) has posted 2/9 posts (22%)  
**And** Urban pillar (25% weight) has posted 3/8 posts (37%)  
**When** strategy selects next post  
**Then** Thanksgiving pillar is selected (most behind target)  
**And** photo is from Thanksgiving pillar's clusters  
**And** caption uses Thanksgiving guidelines (grateful tone)

#### Scenario: Exclude expired pillar

**Given** Thanksgiving pillar with end_date Dec 5, 2024  
**And** Current date is Dec 10, 2024  
**When** strategy selects next pillar  
**Then** Thanksgiving pillar is not considered  
**And** next active pillar is selected

---

### REQ-5: Dashboard Pillar Visualization

**ID**: `PILLAR-005`  
**Priority**: Medium  
**Type**: Functional

**Description:**  
Dashboard shall display content pillar hierarchy, showing pillars → clusters → photos with gap analysis.

**Acceptance Criteria:**
- Shows all active pillars for persona
- Displays pillar weight, date range, target posts
- Lists clusters assigned to each pillar
- Shows photo counts (total, unposted) per cluster
- Indicates gap status (🔴 critical, ⚠️ low, ✅ ready)

#### Scenario: Display pillar hierarchy

**Given** Thanksgiving pillar with 3 assigned clusters  
**And** Each cluster has photos  
**When** I view dashboard  
**Then** I see "Thanksgiving 2024 (30%, Nov 7-Dec 5)"  
**And** I see "Target: 9 posts | Available: 5 photos | Gap: 4"  
**And** I see list of 3 clusters with photo counts  
**And** I see action: "Need 4 more photos"

---

### REQ-6: Pillar Management CLI

**ID**: `PILLAR-006`  
**Priority**: Medium  
**Type**: Functional

**Description:**  
Provide CLI commands for pillar lifecycle management.

**Acceptance Criteria:**
- Create pillar: `rails pillars:create`
- List pillars: `rails pillars:list`
- Show pillar details: `rails pillars:show`
- Assign cluster: `rails pillars:assign_cluster`
- Gap analysis: `rails pillars:gaps`

#### Scenario: Create pillar via CLI

**Given** Sarah persona exists  
**When** I run `rails pillars:create PERSONA=sarah NAME="Thanksgiving 2024" WEIGHT=30`  
**Then** pillar is created  
**And** output confirms creation with pillar ID  
**And** `rails pillars:list` shows the new pillar

---

## Data Model

```
┌─────────────────┐
│   Personas      │
└────────┬────────┘
         │ 1:N
         ▼
┌─────────────────────┐       ┌─────────────────────────┐
│  ContentPillars     │ N:M   │ PillarCluster           │
│  ─────────────────  │◄─────►│ Assignments             │
│  - name             │       │ ──────────────────────  │
│  - weight (%)       │       │ - pillar_id (FK)        │
│  - guidelines       │       │ - cluster_id (FK)       │
│  - active           │       │ - primary (boolean)     │
└─────────────────────┘       └──────────┬──────────────┘
                                         │ N:M
                                         ▼
                              ┌─────────────────────┐
                              │  Clusters           │
                              │  ─────────────────  │
                              │  - persona_id (FK)  │
                              └──────────┬──────────┘
                                         │ 1:N
                                         ▼
                                   ┌──────────┐
                                   │  Photos  │
                                   └──────────┘
```

---

## Non-Functional Requirements

**Performance:**
- Pillar selection < 50ms
- Gap analysis for 30 days < 200ms
- Dashboard render < 500ms

**Scalability:**
- Support 10 active pillars per persona
- Support 50 clusters per pillar

---

## Dependencies

- Requires: `clustering` capability
- Requires: `content-strategy` capability
- Enhances: `scheduling` capability
