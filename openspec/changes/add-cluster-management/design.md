## Context

The clustering engine (Milestone 4a) generates groups of visually similar photos using K-Means on DINO embeddings. However, these clusters are unnamed and un-curated, making them difficult to use for content strategies. This change provides human-in-the-loop curation tools.

**Current State:**
- `Photos::Cluster` model exists in `packs/photos` with `name`, `status`, `photos_count`
- `Photos::ClusteringService` generates clusters using K-Means algorithm
- `clustering:generate` rake task triggers the clustering process
- No tools exist to review or name clusters

**Constraints:**
- Console-only interface (no web UI)
- Must work with existing cluster data (no schema changes)
- Must maintain pack boundaries and encapsulation

## Goals / Non-Goals

**Goals:**
- Properly organize clustering logic in dedicated pack
- Enable efficient cluster review via sample image export
- Provide simple naming/renaming for clusters
- Maintain backward compatibility with existing cluster data

**Non-Goals:**
- Web-based UI for cluster management
- Automatic cluster naming using AI
- Manual photo reassignment between clusters
- Marking clusters as "unusable" (removed from original spec)

## Decisions

### Decision 1: Create Dedicated Clustering Pack
**What:** Extract all clustering logic from `packs/photos` into new `packs/clustering` pack.

**Why:**
- Clustering is a distinct domain concern separate from photo storage/management
- Enables clearer boundaries and dependencies
- Makes clustering features easier to test and maintain in isolation
- Follows project convention of domain-specific packs

**Alternatives considered:**
- Keep in `packs/photos`: Creates tight coupling and mixed concerns
- Create during Milestone 4c: Would require refactoring later when adding content strategies

### Decision 2: Console-Based Commands Using GLCommand
**What:** Implement curation workflow as three separate GLCommand classes called via Rails console.

**Why:**
- Aligns with project convention of using GLCommand for business logic
- Provides scriptable, testable interface
- Avoids premature UI development
- Sufficient for manual curation workflow (not high-frequency operation)

**Alternatives considered:**
- Web UI: Over-engineered for Milestone 4b; can be added later if needed
- Single monolithic command: Would violate single responsibility principle
- Rake tasks: Less flexible than GLCommand, harder to test and chain

### Decision 3: Image Export for Visual Inspection
**What:** `ViewCluster` copies sample images to `/tmp/cluster_samples/cluster_<id>/` directory.

**Why:**
- Allows visual inspection using native OS file browser/viewer
- No dependencies on specific image viewers or terminal graphics
- Works across all development environments (local, remote, containers)
- Temporary directory automatically cleaned by OS

**Alternatives considered:**
- Display in terminal (iTerm2 imgcat): Not portable across environments
- Open in browser: Requires web server, more complexity
- Print file paths only: Requires manual file opening, slower workflow

## Risks / Trade-offs

### Risk: Model Namespace Change
**Impact:** Existing code references to `Photos::Cluster` will break.

**Mitigation:**
- Search codebase for all references before refactoring
- Update all associations in `Photos::Photo` model
- Run full test suite to catch any missed references

### Trade-off: Console-Only Interface
**Benefit:** Fast to implement, no UI dependencies.

**Cost:** Less user-friendly than web UI; requires Rails console knowledge.

**Rationale:** This is acceptable for Milestone 4b as cluster curation is a low-frequency operation performed by technical users. Web UI can be added in future milestone if needed.

### Trade-off: File System Export for Preview
**Benefit:** Simple, portable, works everywhere.

**Cost:** Creates temporary files that need eventual cleanup.

**Rationale:** OS handles temp directory cleanup automatically. The simplicity and reliability outweigh the minor disk usage concern.

## Migration Plan

### Phase 1: Refactoring (No User Impact)
1. Create `packs/clustering` pack structure
2. Move models, services, tasks with namespace updates
3. Update package dependencies
4. Run full test suite to verify no regressions

**Rollback:** Revert commits (no database changes)

### Phase 2: New Commands (Additive)
1. Implement three console commands
2. Add comprehensive unit tests
3. Document console workflow

**Rollback:** Commands are additive; old clustering functionality unchanged

### Phase 3: Documentation Update
1. Update pack READMEs
2. Add usage examples

## Open Questions

None. All requirements are clear from the approved tech spec document.
