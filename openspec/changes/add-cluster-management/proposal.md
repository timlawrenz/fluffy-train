## Why

The automated clustering process (Milestone 4a) produces raw, unnamed groups of images based on visual similarity. These clusters need human curation to be useful for content strategies. Users must be able to review clusters, understand their thematic content, and assign meaningful names (e.g., "Cyberpunk Nights", "Nature Landscapes") to use them effectively in automated posting strategies.

## What Changes

- Refactor existing clustering logic from `packs/photos` to new `packs/clustering` pack for proper encapsulation
- Create console-based commands to list all clusters with photo counts
- Add ability to view sample images from any cluster for visual inspection
- Implement cluster naming/renaming functionality
- Establish foundation for Milestone 4c content strategy engine that will use named clusters

## Impact

- **Affected specs:** New `clustering` capability (no existing specs)
- **Affected code:**
  - Move `Photos::Cluster` model to `Clustering::Cluster` (`packs/clustering/app/models/`)
  - Move `Photos::ClusteringService` to `packs/clustering/app/services/`
  - Move `clustering:generate` rake task to `packs/clustering`
  - Update `Photos::Photo` model to reference `Clustering::Cluster`
  - Create three new console commands: `ListClusters`, `ViewCluster`, `RenameCluster`
  - Update package dependencies: `packs/clustering` depends on `packs/photos`
- **Breaking:** Model namespace change from `Photos::Cluster` to `Clustering::Cluster` (data migration not needed, only code references)
