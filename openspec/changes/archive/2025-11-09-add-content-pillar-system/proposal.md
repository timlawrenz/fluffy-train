# Implementation Proposal: Content Pillar System

## Why

**Current Problem:** fluffy-train has no concept of strategic content pillars. Content selection is purely based on visual clustering (DBSCAN), which creates arbitrary photo groupings without strategic coherence. There's no way to:

1. **Define strategic themes** (e.g., "Thanksgiving 2024 Gratitude", "Urban Lifestyle", "Wellness & Self-Care")
2. **Allocate posting frequency** by theme (30% gratitude, 25% urban, 20% wellness, etc.)
3. **Identify content gaps** ("need 3 cozy home photos for Thanksgiving pillar")
4. **Track pillar coverage** over time (posted 8/9 Thanksgiving posts)
5. **Organize clusters strategically** (multiple clusters feed into one pillar)

**Current State:**
```
Clustering (DBSCAN) → Random Clusters → Strategy Picks Random Photo
```

**Issues:**
- Visual similarity ≠ strategic coherence
- "Beach & Sky Photos" and "Face & Hair Photos" have no strategic meaning
- Can't ensure balanced posting across strategic themes
- No mechanism to identify missing content
- Content strategy is reactive, not proactive

**Desired State:**
```
Content Pillars (Strategic) → Clusters (Tactical) → Photos → Posting Strategy
```

**Example Architecture:**
```
Pillar: "Thanksgiving 2024 Gratitude" (30%, Nov 7-Dec 5)
  ├── Cluster: "Morning Coffee Autumn Light" (5 photos)
  ├── Cluster: "Neighborhood Fall Colors" (3 photos)
  ├── Cluster: "Cozy Home Moments" (4 photos)
  ├── Cluster: "Cafe & Community" (2 photos)
  └── Cluster: "Seasonal Transitions" (3 photos)

Pillar: "Urban Lifestyle" (25%, Ongoing)
  ├── Cluster: "City Street Style" (12 photos)
  ├── Cluster: "Coffee Shop Culture" (8 photos)
  └── Cluster: "Downtown Architecture" (10 photos)

Pillar: "Wellness & Self-Care" (20%, Ongoing)
  ├── Cluster: "Morning Yoga Practice" (6 photos)
  ├── Cluster: "Reading & Relaxation" (5 photos)
  └── Cluster: "Cozy Home Moments" (4 photos)  ← SHARED with Thanksgiving!
```

**Key Insight:** Clusters can belong to **multiple pillars**. "Cozy Home Moments" works for both Thanksgiving and Wellness pillars with different caption/hashtag treatment.

---

## What Changes

This proposal adds a new `content-pillars` capability implementing:

### 1. Content Pillar Model (Strategic Layer)

**Database: `content_pillars` table**
```ruby
class ContentPillar < ApplicationRecord
  belongs_to :persona
  has_many :pillar_cluster_assignments, dependent: :destroy
  has_many :clusters, through: :pillar_cluster_assignments
  
  # Strategic attributes
  - name: string (e.g., "Thanksgiving 2024 Gratitude")
  - description: text (pillar purpose and guidelines)
  - weight: decimal (0-100, posting frequency allocation %)
  - active: boolean (currently in rotation)
  - start_date: date (optional, for seasonal/campaign pillars)
  - end_date: date (optional)
  
  # Configuration
  - guidelines: jsonb {
      tone: ["grateful", "understated"],
      topics: ["autumn", "gratitude", "cozy moments"],
      avoid_topics: ["food", "turkey", "traditional thanksgiving"],
      style_notes: "Soft, unassuming charm. 0-1 emoji max."
    }
  - target_posts_per_week: integer (optional, overrides weight)
  - priority: integer (1-5, for tie-breaking)
end
```

### 2. Pillar-Cluster Join Table (Many-to-Many)

**Database: `pillar_cluster_assignments` table**
```ruby
class PillarClusterAssignment < ApplicationRecord
  belongs_to :pillar, class_name: 'ContentPillar'
  belongs_to :cluster, class_name: 'Clustering::Cluster'
  
  # Assignment metadata
  - notes: text (why this cluster fits this pillar)
  - primary: boolean (is this cluster's main pillar?)
  - created_at: timestamp
  
  # Validation
  validates :pillar, :cluster, presence: true
  validates :cluster_id, uniqueness: { scope: :pillar_id }
end
```

**Benefits of Join Table:**
- **Flexibility**: One cluster can serve multiple pillars
- **Reusability**: "Cozy Home" photos work for Thanksgiving AND Wellness
- **Strategic clarity**: See all clusters feeding each pillar
- **Caption variation**: Same photo, different pillar = different caption/hashtags

### 3. Enhanced Cluster Model

**Modifications to `clusters` table:**
```ruby
# NO pillar_id column! Use join table instead.
# But add metadata for pillar-aware strategies:

class Clustering::Cluster
  has_many :pillar_cluster_assignments, foreign_key: :cluster_id, dependent: :destroy
  has_many :pillars, through: :pillar_cluster_assignments, source: :pillar
  
  # New scope
  scope :for_pillar, ->(pillar) { joins(:pillar_cluster_assignments)
                                   .where(pillar_cluster_assignments: { pillar_id: pillar.id }) }
  
  # Helper methods
  def primary_pillar
    pillar_cluster_assignments.find_by(primary: true)&.pillar
  end
  
  def pillar_names
    pillars.pluck(:name)
  end
end
```

### 4. Pillar-Aware Content Strategy

**Enhanced Strategy Selection:**
```ruby
class ContentStrategy::SelectNextPost
  def call
    # 1. Determine which pillar to post from (based on weights & rotation)
    pillar = select_next_pillar(persona)
    
    # 2. Find available clusters for that pillar
    available_clusters = pillar.clusters
      .joins(:photos)
      .where(photos: { persona_id: persona.id })
      .where.not(photos: { id: posted_photo_ids })
      .distinct
    
    # 3. Select photo from pillar-appropriate cluster
    cluster = strategy.select_cluster(available_clusters, pillar: pillar)
    photo = strategy.select_photo(cluster)
    
    # 4. Generate caption/hashtags aligned with pillar
    caption = generate_caption(photo, pillar: pillar)
    hashtags = generate_hashtags(photo, pillar: pillar)
    
    # 5. Record pillar in posting history
    ContentStrategy::HistoryRecord.create!(
      persona: persona,
      photo: photo,
      cluster: cluster,
      pillar: pillar,  # NEW
      strategy_name: strategy.name
    )
  end
  
  private
  
  def select_next_pillar(persona)
    # Weighted rotation algorithm
    # Example: 30% Thanksgiving, 25% Urban, 20% Wellness
    # Returns pillar that's most "behind" its target weight
  end
end
```

### 5. Content Gap Analysis

**New Service: `ContentPillars::GapAnalyzer`**
```ruby
class ContentPillars::GapAnalyzer
  def analyze(persona, days_ahead: 30)
    pillars = persona.content_pillars.active
    
    pillars.map do |pillar|
      # Calculate expected posts based on weight
      total_posts_needed = calculate_posts_needed(persona, days_ahead)
      pillar_posts_needed = (total_posts_needed * pillar.weight / 100.0).ceil
      
      # Count available photos
      available_photos = pillar.clusters
        .flat_map(&:photos)
        .reject { |p| posted?(p) }
        .uniq
        .count
      
      # Calculate gap
      gap = pillar_posts_needed - available_photos
      
      {
        pillar: pillar,
        posts_needed: pillar_posts_needed,
        photos_available: available_photos,
        gap: gap,
        status: gap > 0 ? :needs_content : :ready
      }
    end
  end
end
```

### 6. Dashboard Integration

**Enhanced Dashboard showing pillars:**
```
📚 CONTENT PILLARS & CLUSTERS
────────────────────────────────────────
📌 Thanksgiving 2024 Gratitude (30%, Nov 7-Dec 5)
   🎯 Target: 9 posts | Available: 0 photos | 🔴 Gap: 9 photos
   
   Clusters (0 assigned):
   └─ No clusters assigned yet
   
   Action: Create clusters and assign photos

📌 Urban Lifestyle (25%, Ongoing)  
   🎯 Target: 8 posts/month | Available: 15 photos | ✅ Ready
   
   Clusters (2):
   ├─ ✅ City Street Style (5 unposted photos)
   └─ ✅ Coffee Shop Culture (3 unposted photos)

📌 Wellness & Self-Care (20%, Ongoing)
   🎯 Target: 6 posts/month | Available: 4 photos | ⚠️  Gap: 2 photos
   
   Clusters (1):
   └─ ⚠️  Cozy Home Moments (4 unposted photos) [Shared with Thanksgiving]
```

### 7. Pillar Management Commands

**New Rake Tasks:**
```bash
# List pillars
rails pillars:list PERSONA=sarah

# Create pillar
rails pillars:create PERSONA=sarah NAME="Thanksgiving 2024" WEIGHT=30

# Assign cluster to pillar
rails pillars:assign_cluster PILLAR_ID=1 CLUSTER_ID=5 PRIMARY=true

# Show gap analysis
rails pillars:gaps PERSONA=sarah DAYS=30

# Show pillar details
rails pillars:show PILLAR_ID=1
```

---

## Impact

**Affected Specs:**
- ADDED: `content-pillars` (new capability spec)
- MODIFIED: `clustering` (add pillar associations)
- MODIFIED: `content-strategy` (pillar-aware selection)

**Affected Code:**
- New pack: `packs/content_pillars/`
- New table: `content_pillars`
- New table: `pillar_cluster_assignments`
- Modified: `packs/clustering/` (add pillar associations)
- Modified: `packs/content_strategy/` (pillar-aware strategies)
- Enhanced: `lib/tasks/content_dashboard.rake`
- New: `lib/tasks/pillars.rake`

**Benefits:**
- **Strategic alignment**: Content matches persona's strategic themes
- **Content planning**: Know exactly what content to create
- **Gap identification**: System tells you what's missing
- **Balanced posting**: Automatic rotation ensures pillar coverage
- **Campaign support**: Time-bound pillars for seasonal content
- **Cluster reusability**: One cluster serves multiple strategic purposes

**Risks:**
- **Added complexity**: Another layer in content selection
- **Migration needed**: Existing clusters need pillar assignment
- **Strategy changes**: Existing strategies need pillar awareness
- **Mitigation**: Feature flag, gradual rollout, backward compatibility

**Breaking Changes:** 
- None - additive only. Existing cluster-only strategies still work.

---

## Timeline

**Estimated Duration:** 1 week to production-ready MVP

**Phase 1: Foundation (Days 1-2)**
- Database migrations (content_pillars, pillar_cluster_assignments)
- ContentPillar model
- PillarClusterAssignment model  
- Basic validations and associations

**Phase 2: Integration (Days 3-4)**
- Cluster model enhancements (pillar associations)
- GapAnalyzer service
- Pillar management rake tasks
- Dashboard integration

**Phase 3: Strategy Integration (Days 5-6)**
- Pillar-aware SelectNextPost
- Weighted rotation algorithm
- Caption/hashtag pillar alignment
- History tracking with pillar

**Phase 4: Polish (Day 7)**
- Documentation
- Migration guide for existing clusters
- Testing
- Deployment

---

## Success Metrics

**Functionality:**
- ✅ Can create and manage content pillars
- ✅ Can assign multiple clusters to one pillar
- ✅ Can assign one cluster to multiple pillars
- ✅ Gap analysis identifies missing content
- ✅ Strategy respects pillar weights
- ✅ Dashboard shows pillar hierarchy

**Quality:**
- ✅ All tests passing
- ✅ Backward compatible with non-pillar workflows
- ✅ Zero manual cluster assignment errors (FK constraints)

**Usage:**
- ✅ Sarah's Thanksgiving 2024 pillar configured
- ✅ 9 posts scheduled across proper clusters
- ✅ Pillar weights maintain strategic balance

---

## References

- `docs/content-plans/sarah-thanksgiving-2024.md` - Real-world pillar example
- `docs/research/content-strategy-engine/content-creation-architecture.md` - Architecture design
- `docs/content-pillars-clusters-guide.md` - Best practices
