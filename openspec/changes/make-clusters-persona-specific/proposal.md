# Make Clusters Persona-Specific

## Why

**Current Problem:**
Clusters are currently global entities without explicit persona ownership. While the system indirectly scopes clusters by persona through photo relationships (`Clustering::Cluster.joins(:photos).where(photos: { persona_id: persona.id })`), this creates several issues:

1. **No Data Integrity**: Nothing prevents a cluster from containing photos from multiple personas
2. **Unclear Ownership**: Clusters have no clear owner, making management and permissions ambiguous
3. **Inefficient Queries**: Content strategy must join through photos table to find persona's clusters
4. **Potential Data Leakage**: A cluster could theoretically be shared across personas, mixing content
5. **Confusing Admin UI**: Cluster management doesn't show which persona owns which clusters

**Current Architecture:**
```
Cluster (id, name, status, photos_count)
  ↓ has_many
Photo (id, path, persona_id, cluster_id)
  ↓ belongs_to
Persona (id, name)
```

**Issue Example:**
- Cluster "Beach Photos" could theoretically contain Sarah's beach photos AND TechReviewer's beach photos
- Content strategy for Sarah filters: `Cluster.joins(:photos).where(photos: { persona_id: sarah.id })`
- If one photo from TechReviewer is accidentally assigned to Sarah's cluster, the cluster becomes "shared"

**Real-World Impact:**
- Clustering service runs per persona but creates global clusters
- No database constraint enforces persona isolation
- Admin interfaces don't clearly show cluster ownership
- Future multi-tenant scenarios would be problematic

## What Changes

Add explicit `persona_id` foreign key to clusters table to establish clear ownership and improve data integrity.

**Database Schema:**
- Add `persona_id` column to `clusters` table (foreign key to personas)
- Add `NOT NULL` constraint (all clusters must have an owner)
- Add index on `persona_id` for efficient queries
- Add database constraint to prevent orphaned clusters

**Model Changes:**
- `Clustering::Cluster` gains `belongs_to :persona`
- `Persona` gains `has_many :clusters`
- Update scopes: `Cluster.for_persona(persona_id)`
- Validate persona presence on cluster creation

**Content Strategy Changes:**
- Simplify cluster queries: `persona.clusters` instead of `Cluster.joins(:photos).where(...)`
- Update `Context#available_clusters` to use direct relationship
- Remove unnecessary joins through photos table

**Clustering Service Changes:**
- Accept persona parameter (already does this implicitly)
- Assign persona_id when creating clusters
- Scope cluster queries by persona

**Migration Strategy:**
1. Add `persona_id` column (nullable initially)
2. Backfill existing clusters by analyzing their photos
3. Add NOT NULL constraint after backfill
4. Add foreign key constraint

**Breaking Changes:**
- ⚠️ Cluster creation now requires persona_id
- ⚠️ Global cluster queries without persona filter will need updates
- ⚠️ Any direct SQL accessing clusters table needs persona_id

## Impact

**Affected Specs:**
- NEW: `clustering` (create spec for cluster management capability)
- MODIFIED: `content-strategy` (simplified cluster queries)

**Affected Code:**
- `packs/clustering/app/models/clustering/cluster.rb` - Add persona relationship
- `packs/personas/app/models/persona.rb` - Add clusters relationship  
- `packs/clustering/app/services/clustering/clustering_service.rb` - Assign persona_id
- `packs/content_strategy/app/services/content_strategy/context.rb` - Simplify available_clusters
- `packs/clustering/app/commands/clustering/*.rb` - Scope by persona
- `db/migrate/` - New migration for persona_id column

**Database Migration Impact:**
- Data backfill required for existing clusters
- Potential for orphaned clusters (clusters with no photos)
- Need to handle edge cases (multiple personas in one cluster)

**Benefits:**
- ✅ Explicit ownership model
- ✅ Better data integrity (FK constraints)
- ✅ Faster queries (no joins needed)
- ✅ Clearer admin UI
- ✅ Easier multi-tenancy support
- ✅ Simplified content strategy code

**Risks:**
- Migration complexity for existing data
- Potential for clusters with mixed-persona photos (need decision on handling)
- Breaking change for any external code expecting global clusters
