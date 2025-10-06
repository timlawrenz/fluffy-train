---
project: fluffy-train
status: done
---

# Tech Spec: Core Clustering Engine

This document outlines the technical approach for implementing the Core Clustering Engine, as defined in Milestone 4a of the product roadmap.

*   **Feature Name:** Core Clustering Engine
*   **Problem Statement:** The photo library is currently an undifferentiated collection of images. To enable thematic content strategies (e.g., "Theme of the Week"), we need an automated way to group visually and thematically similar images together without requiring manual categorization.
*   **Proposed High-Level Solution:** An automated script will apply a clustering algorithm to the DINO embeddings of all usable photos. The resulting cluster assignment for each photo will be saved to the database.
*   **Primary Pack:** `packs/photos`
*   **Key Goals:**
    *   Process a library of 1,000+ images and assign a cluster ID to each.
    *   Persistently store the cluster assignments in the database.
    *   Ensure the resulting clusters are thematically and aesthetically coherent upon visual inspection.
*   **Key Non-Goals:**
    *   This milestone does not include creating a UI for viewing or managing clusters.
    *   Naming, curating, or otherwise adding human-in-the-loop feedback to clusters is out of scope.
    *   Integrating these clusters into any posting or content selection strategy is out of scope.

---

## 1. Data Model Changes

To support clustering, we will introduce a new model and update an existing one. This approach is chosen to be forward-compatible with Milestone 4b, which will require storing metadata about each cluster (like a human-readable name).

### New Table: `clusters`

We will create a new `clusters` table to store information about each generated cluster.

*   **Model Name:** `Cluster`
*   **Pack:** `packs/photos`
*   **Schema:**
    *   `name` (string, nullable): To be used in Milestone 4b for curation.
    *   `status` (integer, default: 0): An enum to manage state (e.g., `active`, `unusable`).
    *   `photos_count` (integer, default: 0): A counter cache for the number of photos in the cluster.

A migration will be created to establish this table.

### Modification to `photos` Table

We will add a foreign key to the `photos` table to associate each photo with a cluster.

*   **Model Name:** `Photo`
*   **Change:** Add a `cluster_id` column.
*   **Details:**
    *   `cluster_id` (bigint, nullable, foreign_key: true)
    *   An index will be added to `cluster_id` to ensure efficient lookups.

The `Photo` model will be updated with `belongs_to :cluster, counter_cache: true`. The `Cluster` model will have `has_many :photos`.

## 2. Clustering Algorithm and Implementation

### Algorithm Choice

We will start with the **K-Means** clustering algorithm.

*   **Reasoning:** K-Means is a well-understood, computationally efficient algorithm suitable for our initial needs. While it requires specifying the number of clusters (`k`) beforehand, this provides a predictable structure to start with.
*   **Configuration:** The value of `k` will be externalized into a configuration file (e.g., `image_embed.yml`) to allow for easy experimentation without code changes.

The implementation will be modular to allow for swapping in other algorithms like DBSCAN in the future if required.

### Implementation Details

The core logic will be encapsulated in a service object within `packs/photos`.

1.  **Service Object:** `ClusteringService`
    *   **Location:** `packs/photos/app/services/photos/clustering_service.rb`
    *   **Responsibilities:**
        *   Fetch all `Photo` records that have DINO embeddings but have not yet been assigned to a cluster.
        *   Handle potential memory issues by processing photos in batches if the library is very large.
        *   Interface with a Ruby-based machine learning library (e.g., `rumale`) to perform the K-Means clustering on the DINO embeddings.
        *   Create the new `Cluster` records in the database.
        *   Update the `photos` table to assign the correct `cluster_id` to each photo.

2.  **Rake Task:** `clustering:generate`
    *   **Location:** `packs/photos/lib/tasks/clustering.rake`
    *   **Purpose:** Provide a command-line interface to trigger the clustering process.
    *   **Action:** The task will simply instantiate `Photos::ClusteringService` and invoke it. This will be the primary entry point for running the clustering process, whether manually or via a scheduled job in the future.

The entire update process within the service will be wrapped in a single database transaction to ensure data integrity. If any part of the assignment fails, the entire process will be rolled back.

## 3. Testing Strategy

1.  **Model Specs:**
    *   Unit tests for the new `Cluster` model to validate its associations and any future logic.
    *   Updates to the `Photo` model spec to validate the new `belongs_to :cluster` association.

2.  **Service Spec:**
    *   A unit test for `Photos::ClusteringService`. This test will use a small, deterministic set of mock embeddings and verify that the service correctly assigns cluster IDs to photos.

3.  **Integration Spec:**
    *   An integration test for the `clustering:generate` Rake task. This will use fixtures to create a set of photos with embeddings in a test database, run the task, and assert that the photos have been correctly assigned to clusters.

## 4. Open Questions & Risks

*   **Optimal `k` Value:** The ideal number of clusters (`k`) is unknown. This will require empirical testing and visual inspection to find a value that produces meaningful thematic groups. We should plan for a brief period of experimentation.
*   **Performance & Memory:** For a very large photo library (e.g., >100,000 images), loading all DINO embeddings into memory at once could be an issue. The initial implementation will assume it fits, but we must monitor memory usage and be prepared to implement a batching or streaming solution if necessary.
*   **Cluster Quality:** The quality of clusters is subjective. The acceptance criteria of visually inspecting 5 clusters is a good start, but we should be prepared for some clusters to be less coherent than others. This is acceptable for this milestone, as the curation tools in 4b will address this.

## 5. Ticket Dependency Tree

*   [#66: [Setup] Add `rumale` gem for K-Means clustering](https://github.com/timlawrenz/fluffy-train/issues/66)
*   [#64: [Database] Create `clusters` table and model](https://github.com/timlawrenz/fluffy-train/issues/64)
    *   [#67: [Database] Add `cluster_id` foreign key to `photos` table](https://github.com/timlawrenz/fluffy-train/issues/67)
        *   [#65: [Backend] Implement `Photos::ClusteringService`](https://github.com/timlawrenz/fluffy-train/issues/65)
            *   [#63: [Backend] Create `clustering:generate` Rake task](https://github.com/timlawrenz/fluffy-train/issues/63)
                *   [#62: [Testing] Write integration test for the clustering Rake task](https://github.com/timlawrenz/fluffy-train/issues/62)