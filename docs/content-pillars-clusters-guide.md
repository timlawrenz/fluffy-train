# Content Pillar & Cluster Best Practices

**Date**: 2025-11-06  
**Status**: Canonical Guide  
**Purpose**: Define the proper relationship between pillars and clusters

---

## Core Principle

**Pillars drive strategy. Clusters organize execution.**

```
PILLAR (Strategic Theme - Broad)
  └── Multiple CLUSTERS (Content Batches - Specific, 10-30 photos each)
```

---

## Definitions

### Content Pillar
**What**: Strategic theme category that defines content types  
**Scope**: Broad, abstract, long-term  
**Size**: 3-5 pillars per persona  
**Weight**: Percentage of total content (must sum to 100%)  
**Examples**: 
- "Hobbies & Downtime" (25%)
- "Lifestyle & Daily Living" (40%)
- "Seasonal & Events" (5%)

**Purpose**: Strategic planning and content balance

### Cluster
**What**: Specific batch of curated photos with cohesive theme  
**Scope**: Narrow, concrete, campaign-based  
**Size**: 10-30 photos optimal  
**Lifespan**: Single creation session to few weeks  
**Examples**:
- "Gymnastics Floor Routine Nov 2024" (15 photos)
- "Morning Coffee Autumn 2024" (12 photos)
- "Christmas Cozy Evenings Dec 2024" (10 photos)

**Purpose**: Tactical execution and variety management

---

## The Relationship

### One Pillar → Many Clusters

A single pillar should have **multiple smaller clusters**, not one giant cluster.

**Example: "Hobbies & Downtime" Pillar (25% of content)**

```
Pillar: "Hobbies & Downtime" (25%)
  ├── Cluster: "Gymnastics Floor Routine Nov 2024" (15 photos)
  ├── Cluster: "Gymnastics Balance Beam Dec 2024" (12 photos)
  ├── Cluster: "Yoga Morning Practice" (10 photos)
  ├── Cluster: "Reading Cozy Evenings" (12 photos)
  ├── Cluster: "Cooking Adventures Winter" (8 photos)
  └── Cluster: "Weekend Hiking Trails" (10 photos)
```

**Why Multiple Clusters:**
1. **Variety**: Different sub-themes within pillar prevent repetition
2. **Freshness**: Rotate between clusters for diverse content
3. **Quality**: Easier to curate 10-30 photos than 100s
4. **Strategic**: Pick specific cluster based on mood/season/timing
5. **Manageability**: Clear batches from creation sessions

---

## Best Practices

### ✅ DO

**Pillar Level:**
- Define 3-5 strategic pillars per persona
- Assign weights that sum to 100%
- Include seasonal boost adjustments
- Track pillar balance over time

**Cluster Level:**
- Create specific, focused batches (10-30 photos)
- Name descriptively with date/season
- Tag all clusters with pillar_name
- Curate for quality within each batch
- Create multiple clusters per pillar theme

**Rotation:**
- Vary which cluster you post from within pillar
- Track recently used clusters
- Avoid posting from same cluster consecutively
- Balance between different sub-themes

### ❌ DON'T

**Avoid These Mistakes:**
- Creating one massive cluster (100s of photos)
- Mixing too many sub-themes in one cluster
- Using same cluster repeatedly
- Naming clusters too generically
- Forgetting to tag clusters with pillar
- Letting any one cluster dominate a pillar

---

## Sizing Guidelines

### Pillar Size
- **Total pillars**: 3-5 per persona
- **Weight range**: 5-40% each
- **Must sum to**: 100%

### Cluster Size
- **Optimal**: 10-30 photos
- **Minimum**: 5 photos (enough for variety)
- **Maximum**: 50 photos (beyond this, split into sub-clusters)
- **Lifetime**: Created together, used over weeks/months

### Distribution Example

**Pillar: "Hobbies & Downtime" (25% of content = ~1 post/week)**

If posting 4x/week, this pillar gets 1 post/week.

**Distribute across clusters:**
- Week 1: "Gymnastics Floor" cluster
- Week 2: "Yoga Practice" cluster  
- Week 3: "Reading Evenings" cluster
- Week 4: "Gymnastics Beam" cluster
- Week 5: "Cooking" cluster
- (Cycle repeats with variety)

**Result**: Diverse hobby content, no fatigue

---

## Naming Conventions

### Pillar Names
**Format**: Strategic Theme (broad)  
**Examples**:
- "Lifestyle & Daily Living"
- "Hobbies & Downtime"
- "Wellness & Self-Care"
- "Community & Connection"
- "Seasonal & Events"

### Cluster Names
**Format**: Specific Theme + Time Period  
**Pattern**: `[Subject] [Detail] [Month/Season] [Year]`

**Good Examples**:
- "Gymnastics Floor Routine Nov 2024"
- "Morning Coffee Autumn 2024"
- "Thanksgiving Gratitude Nov 2024"
- "Christmas Cozy Evenings Dec 2024"
- "Yoga Sunrise Practice Winter 2024"

**Bad Examples**:
- "Gymnastics" (too broad)
- "Photos" (meaningless)
- "Sarah Content" (no context)
- "November" (no theme)

---

## Content Creation Workflow

### Step 1: Identify Pillar Need
```bash
# Analyze content gaps
rake content:analyze_gaps[sarah]

# Output:
# Pillar: Hobbies & Downtime (25%)
#   Photos needed: 3 by Nov 20
#   Sub-theme needed: Gymnastics (last posted 3 weeks ago)
```

### Step 2: Define Specific Batch
**Decide**: What specific sub-theme/cluster to create?

**Example Decision**:
- **Not**: "Create gymnastics content"
- **Yes**: "Create gymnastics floor routine content with graceful movement focus"

**Specificity matters:**
- Floor routine vs beam work vs training vs competition
- Morning yoga vs evening stretching vs outdoor practice
- Breakfast cooking vs baking vs dinner prep

### Step 3: Generate Focused Batch
```bash
# Generate AI prompt for specific batch
rake content:create_request[sarah,"Hobbies & Downtime","Gymnastics Floor Routine"]

# AI generates detailed prompt focused on:
# - Floor exercise movements
# - Athletic grace and elegance
# - Competition floor setting
# - Dynamic poses in motion
```

### Step 4: Create 20-30 Candidates
- Use AI generation tool with focused prompt
- Generate more than you need (2-3x)
- Aim for variety within the specific theme

### Step 5: Curate Best 10-15
- Select for quality
- Ensure variety within batch
- All should work together cohesively
- Reject anything off-brand or low quality

### Step 6: Import and Cluster
```bash
# Import curated photos
rake photos:import PERSONA=sarah PATH=./gym-floor-nov2024/

# Create specific cluster
rake content:create_cluster[sarah,"Hobbies & Downtime","Gymnastics Floor Routine Nov 2024"]

# Add photos by filename pattern
rake content:add_to_cluster[CLUSTER_ID,"gym-floor-*"]
```

### Step 7: Repeat for Other Sub-Themes
Create different clusters under same pillar:
- "Gymnastics Balance Beam Dec 2024"
- "Yoga Morning Practice Nov 2024"
- "Reading Cozy Evenings Winter 2024"

---

## Variety Management

### Within a Pillar

**Pillar: "Hobbies & Downtime" (25%)**

**Bad Pattern** ❌:
```
Week 1: Gymnastics floor (from 200-photo gymnastics cluster)
Week 2: Gymnastics floor (same cluster)
Week 3: Gymnastics beam (same cluster)
Week 4: Gymnastics floor (same cluster)
```
**Problem**: Repetitive, all gymnastics, no variety

**Good Pattern** ✅:
```
Week 1: Gymnastics floor (15-photo cluster)
Week 2: Yoga practice (10-photo cluster)
Week 3: Reading evening (12-photo cluster)
Week 4: Gymnastics beam (12-photo cluster)
Week 5: Cooking (8-photo cluster)
```
**Benefit**: Diverse hobbies, fresh content, balanced

### Strategy Selection Logic

```ruby
def select_cluster_for_pillar(pillar)
  # Get all clusters for this pillar
  clusters = Cluster.where(pillar_name: pillar.name)
                    .with_available_photos
  
  # Avoid recently used clusters (last 5 posts)
  recent_cluster_ids = recent_posts.last(5).map(&:cluster_id).compact
  
  # Filter out recent clusters
  available_clusters = clusters.where.not(id: recent_cluster_ids)
  
  # Prefer clusters that haven't been used in longer time
  # Or random selection for variety
  available_clusters.sample
end
```

---

## Examples by Persona Type

### Lifestyle Persona (Sarah)

**Pillar: "Lifestyle & Daily Living" (40%)**

Clusters:
- "Morning Coffee Rituals Autumn 2024" (12 photos)
- "Urban Walks Fall Colors Nov 2024" (15 photos)
- "Cozy Home Evenings Winter 2024" (10 photos)
- "Favorite Cafe Spots Dec 2024" (12 photos)
- "Weekend Routines Nov 2024" (10 photos)

**Pillar: "Wellness & Self-Care" (20%)**

Clusters:
- "Yoga Sunrise Practice Fall 2024" (10 photos)
- "Nature Walks Mindfulness Nov 2024" (12 photos)
- "Self-Care Evening Rituals Winter 2024" (8 photos)
- "Meditation Spaces Dec 2024" (10 photos)

### Fitness Persona

**Pillar: "Workouts & Training" (40%)**

Clusters:
- "HIIT Circuit Training Nov 2024" (15 photos)
- "Strength Training Upper Body Dec 2024" (12 photos)
- "Cardio Running Outdoor Fall 2024" (10 photos)
- "Core Workout Routines Nov 2024" (12 photos)

**Pillar: "Transformation Stories" (15%)**

Clusters:
- "30-Day Challenge Week 1" (8 photos)
- "30-Day Challenge Week 4 Results" (6 photos)
- "Client Success Stories Nov 2024" (10 photos)

### Fashion Persona

**Pillar: "Outfit Inspiration" (35%)**

Clusters:
- "Fall Layering Looks Nov 2024" (15 photos)
- "Winter Cozy Outfits Dec 2024" (12 photos)
- "Work Casual Autumn 2024" (10 photos)
- "Weekend Style Fall 2024" (12 photos)

---

## Migration Path

### For Existing Content

If you have existing clusters that are too large:

**Step 1: Audit Current Clusters**
```bash
# List clusters with photo counts
Cluster.all.each do |c|
  puts "#{c.name}: #{c.size} photos"
end
```

**Step 2: Identify Large Clusters**
Any cluster > 50 photos should be split

**Step 3: Split Into Sub-Clusters**
```ruby
# Example: Split "Gymnastics" (200 photos) into themed batches

# Analyze photos and group by sub-theme
gymnastics_photos = Cluster.find_by(name: 'Gymnastics').photos

floor_photos = gymnastics_photos.select { |p| floor_routine?(p) }
beam_photos = gymnastics_photos.select { |p| beam_work?(p) }
training_photos = gymnastics_photos.select { |p| training_session?(p) }

# Create new specific clusters
floor_cluster = Cluster.create!(
  name: 'Gymnastics Floor Routine Nov 2024',
  pillar_name: 'Hobbies & Downtime'
)

floor_photos.each { |p| floor_cluster.add_photo(p) }
```

**Step 4: Deprecate Old Large Cluster**
```ruby
old_cluster.update!(
  name: '[DEPRECATED] Gymnastics - Split into sub-clusters',
  pillar_name: nil
)
```

---

## Technical Implementation

### Database Schema

```ruby
# Clusters table
create_table :clusters do |t|
  t.references :persona, null: false
  t.string :name, null: false
  t.string :pillar_name          # NEW: Links to pillar
  t.jsonb :pillar_metadata        # NEW: Pillar-specific data
  t.integer :size, default: 0
  t.timestamps
end

add_index :clusters, :pillar_name
add_index :clusters, [:persona_id, :pillar_name]
```

### Validation Rules

```ruby
class Cluster < ApplicationRecord
  validates :name, presence: true, uniqueness: { scope: :persona_id }
  validates :pillar_name, presence: true
  validate :reasonable_size
  
  private
  
  def reasonable_size
    if size > 50
      errors.add(:size, "should be 50 or less. Consider splitting into sub-clusters.")
    end
  end
end
```

---

## Success Metrics

### Track These Per Pillar

1. **Coverage**: Are all pillars getting content?
2. **Variety**: Using multiple clusters per pillar?
3. **Freshness**: Rotating between clusters?
4. **Performance**: Which clusters/sub-themes perform best?

### Track These Per Cluster

1. **Utilization**: How many photos used vs available?
2. **Lifespan**: Created date to last photo used?
3. **Performance**: Engagement from this cluster's posts?
4. **Depletion**: When will cluster run out of photos?

---

## Summary

### Golden Rules

1. **One Pillar → Many Clusters** (not one-to-one)
2. **Clusters are Specific** (10-30 photos, focused theme)
3. **Pillars are Strategic** (3-5 total, sum to 100%)
4. **Variety Through Rotation** (use different clusters within pillar)
5. **Quality Through Curation** (small batches, high standards)

### Quick Reference

**Creating Content:**
```
Define pillar need → Choose specific sub-theme → 
Generate focused batch → Curate 10-30 → 
Create cluster → Tag with pillar → Schedule from cluster
```

**Posting Strategy:**
```
Time to post pillar → Check recent clusters used → 
Select different cluster → Pick photo → 
Generate caption/hashtags → Schedule post
```

---

**Status**: ✅ Canonical Guide - Use as Reference  
**Next**: Implement in architecture and tooling  
**Priority**: Foundation for all future content creation

---

*Solidified: 2025-11-06*  
*Principle: Pillars drive strategy, Clusters organize execution*
