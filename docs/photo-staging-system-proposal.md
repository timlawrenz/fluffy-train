# Photo Staging System - Design Proposal

## Problem Statement

Current workflow imports photos directly into the system, making it:
- Hard to review for Instagram compliance before clustering
- Impossible to preview captions before import
- Difficult to curate content strategically

## Proposed Solution: 3-Stage Pipeline

### Stage 1: Staging Area (Pre-Import)
**Location**: `public/sarah/staging/`

**Features**:
- Photos sit here before entering the system
- No database records yet
- Quick preview possible
- Manual approval required

**Command**: `rake photos:stage PERSONA=sarah PATH=/path/to/photos`

### Stage 2: Preview & Analysis
**Process**:
1. Run AI analysis on staged photo (without saving)
2. Generate test caption
3. Predict cluster assignment
4. Show Instagram compliance check
5. Present for approval

**Command**: `rake photos:preview_staged PERSONA=sarah`

**Output**:
```
📸 Staged Photo Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File: sarah.a1_2024-11-21_00150_.png

🎨 AI Analysis (Preview):
  Sharpness: 8.2
  Exposure: 7.5
  Aesthetic: 8.0
  Objects: [woman, cafe, coffee, window]

📊 Predicted Cluster: "Coffee Culture" (87% confidence)
   Similar to: 12 existing photos

💬 Generated Caption Preview:
   "Stumbled into the coziest morning ritual ☕"
   
   Quality: 8.5/10
   Tone Match: ✓ Casual, understated
   Instagram Safe: ✓ No compliance issues

✅ APPROVE and import?
❌ REJECT and skip?
📝 EDIT caption then import?
```

### Stage 3: Selective Import
**Options**:
1. **Approve** - Import with all analysis saved
2. **Reject** - Move to rejected folder
3. **Edit** - Save custom caption, then import

**Command**: `rake photos:import_approved PERSONA=sarah`

---

## Implementation Plan

### 1. New Database Model: `StagedPhoto`

```ruby
class StagedPhoto < ApplicationRecord
  belongs_to :persona
  
  # Path in staging directory
  attribute :staging_path, :string
  
  # Preview data (not final)
  attribute :preview_analysis, :jsonb
  attribute :preview_caption, :text
  attribute :predicted_cluster, :string
  attribute :confidence_score, :decimal
  
  # Decision tracking
  attribute :status, :string  # pending, approved, rejected
  attribute :reviewed_at, :datetime
  attribute :rejection_reason, :text
  
  # Custom overrides
  attribute :custom_caption, :text
end
```

### 2. Staging Workflow Commands

**`rake photos:stage`** - Copy photos to staging area
```ruby
# Copies files, creates StagedPhoto records
# No AI analysis yet - just cataloging
```

**`rake photos:analyze_staged`** - Run AI preview (batch)
```ruby
# For each staged photo:
# - Run sharpness/exposure/aesthetic
# - Generate test caption
# - Predict cluster (if enough photos exist)
# - Check Instagram compliance
# - Save preview data (not final)
```

**`rake photos:review_staged`** - Interactive review
```ruby
# Shows each photo with preview data
# Prompts for: Approve / Reject / Edit
# Tracks decisions
```

**`rake photos:import_approved`** - Finalize import
```ruby
# Only approved photos
# Creates Photo records
# Runs full analysis pipeline
# Actually clusters
```

### 3. Compliance Checker

```ruby
module Photos
  class ComplianceChecker
    RISKY_KEYWORDS = [
      'lingerie', 'underwear', 'intimate', 
      'provocative', 'suggestive'
    ]
    
    def check(image_path)
      objects = detect_objects(image_path)
      description = generate_description(image_path)
      
      issues = []
      issues << "Detected lingerie" if objects.include?('lingerie')
      issues << "Suggestive pose" if suggestive_pose?(description)
      issues << "Minimal clothing" if minimal_clothing?(objects)
      
      {
        safe: issues.empty?,
        issues: issues,
        confidence: calculate_confidence(issues)
      }
    end
  end
end
```

### 4. Cluster Prediction (Before Import)

**Challenge**: Can't cluster without importing
**Solution**: Predict based on existing clusters

```ruby
module Photos
  class ClusterPredictor
    def predict(image_path, persona)
      # Get embedding for staged photo
      embedding = ImageEmbedClient.generate_embedding(image_path)
      
      # Compare to existing cluster centroids
      existing_clusters = Clustering::Cluster
        .where(persona: persona)
        .includes(:photos)
      
      return nil if existing_clusters.empty?
      
      # Calculate similarity to each cluster
      similarities = existing_clusters.map do |cluster|
        centroid = calculate_centroid(cluster.photos)
        distance = cosine_similarity(embedding, centroid)
        { cluster: cluster, distance: distance }
      end
      
      # Return most similar cluster
      best_match = similarities.max_by { |s| s[:distance] }
      
      {
        cluster_name: best_match[:cluster].name,
        confidence: best_match[:distance],
        reasoning: "Similar to #{best_match[:cluster].photos.count} photos"
      }
    end
  end
end
```

---

## Usage Examples

### Scenario 1: Fresh Start with Staging

```bash
# 1. Move all new photos to staging
rake photos:stage PERSONA=sarah PATH=/path/to/new/sarah/photos

# 2. Analyze staged photos (preview only)
rake photos:analyze_staged PERSONA=sarah

# 3. Review interactively
rake photos:review_staged PERSONA=sarah
# Shows each photo, asks Approve/Reject/Edit

# 4. Import only approved
rake photos:import_approved PERSONA=sarah
```

### Scenario 2: Clean Slate

```bash
# Remove all unposted photos
rake photos:remove_unposted PERSONA=sarah

# Start fresh with staging
rake photos:stage PERSONA=sarah PATH=/new/compliant/photos
rake photos:analyze_staged PERSONA=sarah
rake photos:review_staged PERSONA=sarah
```

### Scenario 3: Audit Existing

```bash
# Re-analyze existing photos for compliance
rake photos:audit_compliance PERSONA=sarah

# Shows any risky photos
# Generates report of potential issues
```

---

## Migration Strategy

### Option A: Keep Some, Stage New
1. Audit existing photos for compliance
2. Remove non-compliant
3. Use staging for all future imports
4. Gradually improve content pool

### Option B: Fresh Start
1. Remove all unposted photos
2. Start with staging workflow
3. Only import curated, compliant content
4. Rebuild clusters from scratch

### Option C: Hybrid
1. Keep "safe" clusters (Coffee Culture, Urban Exploration)
2. Remove risky clusters (Bikini & Building Photos)
3. Use staging for new content

---

## Benefits

✅ **Preview before commit** - See caption, cluster, compliance
✅ **Manual curation** - Only approved content enters system
✅ **Instagram safety** - Compliance check before import
✅ **Better quality** - Review aesthetic scores before adding
✅ **Flexible workflow** - Batch review or one-by-one
✅ **Reversible** - Rejected photos don't pollute database

## Trade-offs

⚠️ **More manual work** - Requires review step
⚠️ **Slower ingestion** - Not fully automated anymore
⚠️ **Cold start problem** - Still need base photos for clustering

---

## Recommendation

**For your situation:**

1. **Clean slate is simplest**: Remove unposted photos
2. **Implement staging**: Prevents future compliance issues
3. **Start with 50-100 safe photos**: Build clean foundation
4. **Use staging for all new content**: Maintain quality

**Implementation priority:**
1. Basic staging (copy to folder)
2. Compliance checker
3. Caption preview
4. Interactive review
5. Cluster prediction (optional)

Would you like me to implement this staging system?
