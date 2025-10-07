---
project: fluffy-train
status: approved
---

# Tech Spec: Cluster Management & Curation

This document outlines the technical approach for implementing the Cluster Management & Curation tools, as defined in Milestone 4b of the product roadmap.

*   **Feature Name:** Cluster Management & Curation
*   **Problem Statement:** The automated clustering process (Milestone 4a) produces raw, unnamed groups of images. To make these clusters useful for content strategies, we need a way for a human to efficiently review, understand, and name them.
*   **Proposed High-Level Solution:** Create a set of `gl_command`s accessible via the Rails console (`rails c`) that allow a user to list all clusters, view sample images from each, and assign a descriptive name (e.g., "Cyberpunk Nights").
*   **Primary Pack:** `packs/clustering`
*   **Key Goals:**
    *   A user can list all generated clusters and see how many images are in each.
    *   A user can view a representative sample of images for any given cluster.
    *   A user can assign a human-readable name to a cluster.
*   **Key Non-Goals:**
    *   Automatically naming clusters using AI.
    *   Manually moving photos between clusters.
    *   A web-based UI. The entire workflow will be based in the Rails console.
    *   Marking clusters as "unusable" is no longer a requirement.

---

## 1. Prerequisite: Refactoring Existing Clustering Logic

Before implementing the new curation features, the existing clustering logic from Milestone 4a must be moved from `packs/photos` to a new, dedicated pack. This ensures all related logic is properly encapsulated in one place.

### 1.1. New Pack: `packs/clustering`

*   **Action:** A new Packwerk pack will be created to house all business logic related to generating, managing, and curating clusters.
*   **Location:** `packs/clustering`

### 1.2. Code Migration

The following components will be moved:

1.  **Model:** `Photos::Cluster` will be moved to `packs/clustering/app/models/clustering/cluster.rb`. The class will be renamed to `Clustering::Cluster`.
2.  **Service Object:** `Photos::ClusteringService` will be moved to `packs/clustering/app/services/clustering/clustering_service.rb` and renamed.
3.  **Rake Task:** The `clustering:generate` task will be moved from `packs/photos` to `packs/clustering`.
4.  **Tests:** All corresponding spec files for the model and service will be moved to the `packs/clustering/spec/` directory and updated.

### 1.3. Dependency Management

*   `packs/clustering` will be created.
*   `packs/clustering` will declare a dependency on `packs/photos`. This is necessary for the `Clustering::Cluster` model to establish its `has_many :photos` association.
*   The `Photos::Photo` model will be updated to correctly reference `Clustering::Cluster` for its `belongs_to` association.

## 2. Data Model

After the refactoring, the data models will reside in their new locations. No new database migrations are required for this milestone.

*   **`Cluster` Model:** `packs/clustering/app/models/clustering/cluster.rb`
*   **`Photo` Model:** `packs/photos/app/models/photos/photo.rb`

## 3. Console-Based Curation Workflow

The entire user workflow will be conducted within a `rails c` session, using a set of purpose-built `gl_command`s for an interactive and scriptable experience.

### 3.1. Command Implementation

Three distinct commands will be created within the `packs/clustering` pack.

#### 3.1.1. `Clustering::ListClusters`

*   **File:** `packs/clustering/app/commands/clustering/list_clusters.rb`
*   **Purpose:** Provides a high-level summary of all existing clusters.
*   **Arguments:** None.
*   **Logic:**
    1.  Fetches all `Clustering::Cluster` records from the database.
    2.  For each cluster, it uses the `photos_count` counter cache.
    3.  It formats and prints a summary table directly to the console.
    4.  Returns a `GLCommand::Context` with `success: true` and a summary message in `context.message`.
*   **Example Usage:**
    ```ruby
    Clustering::ListClusters.call
    ```
*   **Example Console Output:**
    ```
    ID: 1 | Name: Cluster 1 | Photos: 87
    ID: 2 | Name: Cluster 2 | Photos: 112
    ID: 3 | Name: Cluster 3 | Photos: 54
    ```

#### 3.1.2. `Clustering::ViewCluster`

*   **File:** `packs/clustering/app/commands/clustering/view_cluster.rb`
*   **Purpose:** Allows visual inspection of a cluster by exporting a sample of its images.
*   **Arguments:**
    *   `cluster_id` (Integer, required)
    *   `sample_size` (Integer, optional, default: 10)
*   **Logic:**
    1.  Includes `ActiveModel::Validations` to validate the presence of `cluster_id`.
    2.  Finds the `Clustering::Cluster` by its ID. If not found, it uses `stop_and_fail!` to return an error context.
    3.  Retrieves a random sample of `Photos::Photo` records associated with the cluster.
    4.  Creates a temporary directory (e.g., `/tmp/cluster_samples/cluster_1`).
    5.  Copies the physical image file for each sampled photo into the temporary directory.
    6.  Returns a `GLCommand::Context` with `success: true`. The path to the output directory will be stored in `context.output_path`.
*   **Example Usage:**
    ```ruby
    result = Clustering::ViewCluster.call(cluster_id: 1, sample_size: 5)
    puts result.output_path if result.success?
    ```

#### 3.1.3. `Clustering::RenameCluster`

*   **File:** `packs/clustering/app/commands/clustering/rename_cluster.rb`
*   **Purpose:** Assigns a descriptive, human-readable name to a cluster.
*   **Arguments:**
    *   `cluster_id` (Integer, required)
    *   `new_name` (String, required)
*   **Logic:**
    1.  Includes `ActiveModel::Validations` to validate the presence of both `cluster_id` and `new_name`.
    2.  Finds the `Clustering::Cluster` by its ID. If not found, it uses `stop_and_fail!`.
    3.  Updates the `name` attribute of the cluster record and saves it to the database.
    4.  Returns a `GLCommand::Context` with `success: true` and a confirmation message in `context.message`.
*   **Example Usage:**
    ```ruby
    result = Clustering::RenameCluster.call(cluster_id: 1, new_name: "Cyberpunk Nights")
    puts result.message if result.success?
    ```

## 4. Testing Strategy

*   **Pack Structure:** Tests for the new commands will be located in `packs/clustering/spec/commands/`.
*   **Unit Tests:** Each of the three `gl_command`s will have a corresponding spec file.
    *   **`list_clusters_spec.rb`:** Will test that the command successfully queries clusters and prints output. The console output can be tested by stubbing `puts`.
    *   **`view_cluster_spec.rb`:** Will use fixtures to create a mock cluster and photos. The test will verify that the command correctly creates a directory and copies the expected number of files. `FileUtils` operations will be mocked to avoid actual file I/O.
    *   **`rename_cluster_spec.rb`:** Will test that the command correctly finds a cluster and updates its name attribute. It will also test failure cases, such as providing a non-existent `cluster_id`.

---

## 5. Implementation Tickets

*   **[#77 - [Refactor] Move Clustering Logic to `packs/clustering`](https://github.com/timlawrenz/fluffy-train/issues/77)**
    *   **[#76 - [Backend] Implement `Clustering::ListClusters` Console Command](https://github.com/timlawrenz/fluffy-train/issues/76)**
    *   **[#79 - [Backend] Implement `Clustering::ViewCluster` Console Command](https://github.com/timlawrenz/fluffy-train/issues/79)**
    *   **[#78 - [Backend] Implement `Clustering::RenameCluster` Console Command](https://github.com/timlawrenz/fluffy-train/issues/78)**