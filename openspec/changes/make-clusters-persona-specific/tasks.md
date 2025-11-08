# Tasks: Make Clusters Persona-Specific

**Change ID**: `make-clusters-persona-specific`  
**Status**: Proposal  
**Created**: 2025-11-08

---

## Phase 1: Database Schema Changes (Day 1)

### Migration: Add persona_id Column
- [ ] Create migration to add `persona_id` to clusters table (nullable)
- [ ] Add index on `persona_id`
- [ ] Run migration in development

### Data Backfill Strategy
- [ ] Write backfill script to assign persona_id to existing clusters
- [ ] Logic: For each cluster, find most common persona_id from photos
- [ ] Handle edge cases: clusters with no photos, clusters with mixed personas
- [ ] Test backfill on development data
- [ ] Document backfill decisions in migration comments

### Add Constraints
- [ ] Create second migration to add NOT NULL constraint
- [ ] Add foreign key constraint: `persona_id` references `personas(id)`
- [ ] Add ON DELETE behavior (CASCADE or RESTRICT - decide based on requirements)
- [ ] Run constraint migration

---

## Phase 2: Model Updates (Day 1-2)

### Cluster Model Changes
- [ ] Add `belongs_to :persona` in `Clustering::Cluster`
- [ ] Add validation: `validates :persona, presence: true`
- [ ] Add scope: `scope :for_persona, ->(persona_id) { where(persona_id: persona_id) }`
- [ ] Update existing scopes to include persona filtering where needed
- [ ] Write model specs for persona relationship

### Persona Model Changes
- [ ] Add `has_many :clusters` in `Persona`
- [ ] Add dependent behavior: `has_many :clusters, dependent: :restrict_with_error` (or :destroy if safe)
- [ ] Write specs for clusters relationship

---

## Phase 3: Service Layer Updates (Day 2-3)

### Clustering Service
- [ ] Update `ClusteringService#cluster_photos` to accept and use persona
- [ ] Assign `persona_id` when creating new clusters
- [ ] Add persona validation before clustering
- [ ] Update specs to pass persona parameter
- [ ] Test clustering creates persona-scoped clusters

### Clustering Commands
- [ ] Update `ListClusters` to filter by persona
- [ ] Update `ViewCluster` to verify persona ownership
- [ ] Update `RenameCluster` to verify persona ownership
- [ ] Add authorization checks (persona can only manage own clusters)
- [ ] Write command specs with persona scoping

---

## Phase 4: Content Strategy Updates (Day 3)

### Context Service Simplification
- [ ] Update `Context#available_clusters` to use `persona.clusters` instead of join
- [ ] Remove unnecessary `joins(:photos)` query
- [ ] Update to: `persona.clusters.joins(:photos).where.not(photos: { id: posted_photo_ids }).distinct`
- [ ] Write specs to verify simplified query returns same results
- [ ] Performance test: verify index on persona_id makes queries faster

### Strategy Updates
- [ ] Update `ThemeOfWeekStrategy` cluster selection (if needed)
- [ ] Update `ThematicRotationStrategy` cluster selection (if needed)
- [ ] Verify all strategies use `context.available_clusters` (no direct Cluster queries)
- [ ] Write integration specs for strategies with persona-scoped clusters

---

## Phase 5: Admin UI Updates (Day 4)

### Cluster Management Interface
- [ ] Update cluster list view to show persona name
- [ ] Add persona filter dropdown in cluster admin
- [ ] Ensure cluster creation form includes persona selection
- [ ] Update cluster edit to prevent persona_id changes (or handle carefully)
- [ ] Add breadcrumbs: Persona → Clusters → Cluster Details

### Permissions & Authorization
- [ ] Add policy: users can only view/edit their persona's clusters
- [ ] Update Pundit policies for ClusteringController
- [ ] Test authorization with multiple personas
- [ ] Add specs for cluster authorization

---

## Phase 6: Testing & Validation (Day 4-5)

### Unit Tests
- [ ] Test Cluster model persona relationship
- [ ] Test Cluster validation requires persona
- [ ] Test Persona clusters relationship
- [ ] Test ClusteringService assigns persona_id
- [ ] Test scope: `Cluster.for_persona(persona_id)`

### Integration Tests
- [ ] Test clustering workflow creates persona-scoped clusters
- [ ] Test content strategy queries only persona's clusters
- [ ] Test cluster commands respect persona ownership
- [ ] Test cross-persona isolation (Sarah can't access TechReviewer's clusters)
- [ ] Test backfill migration on test database

### Data Migration Testing
- [ ] Run backfill on staging database
- [ ] Verify all clusters assigned to correct persona
- [ ] Check for clusters with no persona (handle orphans)
- [ ] Validate constraint migration succeeds
- [ ] Document any manual fixes needed

---

## Phase 7: Documentation & Deployment (Day 5)

### Documentation
- [ ] Update README with cluster persona ownership model
- [ ] Document migration process for production
- [ ] Add architectural decision record (ADR) for persona-scoped clusters
- [ ] Update API documentation (if clusters exposed via API)

### Deployment Checklist
- [ ] Review all migration steps
- [ ] Plan production migration window (if needed)
- [ ] Backup production database before migration
- [ ] Run backfill migration
- [ ] Verify backfill results
- [ ] Run constraint migration
- [ ] Deploy code changes
- [ ] Monitor for errors in first 24 hours
- [ ] Rollback plan documented

---

## Acceptance Criteria

### AC1: Database Schema
- [ ] `clusters` table has `persona_id` column (NOT NULL, foreign key)
- [ ] Index exists on `persona_id`
- [ ] All existing clusters assigned to a persona
- [ ] No orphaned clusters

### AC2: Model Relationships
- [ ] `Cluster.belongs_to :persona` works correctly
- [ ] `Persona.has_many :clusters` works correctly
- [ ] Creating cluster without persona fails validation
- [ ] Deleting persona with clusters raises error or cascades (as configured)

### AC3: Content Strategy
- [ ] `context.available_clusters` returns only persona's clusters
- [ ] Query performance improved (no unnecessary joins)
- [ ] Strategies select photos only from persona's clusters
- [ ] No cross-persona data leakage

### AC4: Clustering Service
- [ ] `ClusteringService.cluster_photos(persona:, ...)` assigns persona_id
- [ ] New clusters created with correct persona_id
- [ ] Re-clustering updates existing clusters (same persona only)

### AC5: Admin UI
- [ ] Cluster list shows persona name
- [ ] Users can filter clusters by persona
- [ ] Cluster details show owner persona
- [ ] Authorization prevents cross-persona access

### AC6: Data Integrity
- [ ] Foreign key constraint enforced
- [ ] Cannot create cluster without persona
- [ ] Cannot assign cluster to non-existent persona
- [ ] Photo's persona_id matches cluster's persona_id (or is validated)

---

## Open Questions

1. **Orphaned Clusters:** How to handle clusters with no photos during backfill?
   - [ ] Decision: Delete them or assign to default persona?

2. **Mixed-Persona Clusters:** What if a cluster has photos from multiple personas?
   - [ ] Decision: Assign to majority persona? Split cluster? Manual review?

3. **Delete Behavior:** What happens when persona is deleted?
   - [ ] Decision: `dependent: :destroy` (cascade delete) or `:restrict_with_error` (prevent deletion)?

4. **Photo-Cluster Validation:** Should we add validation that photo.persona_id == cluster.persona_id?
   - [ ] Decision: Add validation or rely on clustering service?

5. **API Compatibility:** Are clusters exposed in any external APIs?
   - [ ] Check: API documentation and external consumers

---

## Dependencies

**Required:**
- Existing Clustering::Cluster model
- Existing Persona model  
- Photos table with persona_id and cluster_id
- Content strategy using available_clusters

**Blocks:**
- None (this is a foundational improvement)

**Blocked By:**
- None (can be done independently)

---

## Related Changes

- `add-cluster-management` (archive) - Original cluster implementation
- `add-content-strategy-engine` (active) - Uses clusters, will be simplified

---

**Last Updated**: 2025-11-08  
**Est. Completion**: 5 days  
**Risk Level**: Medium (migration complexity, data integrity)
