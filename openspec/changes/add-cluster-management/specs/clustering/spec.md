## ADDED Requirements

### Requirement: Cluster Refactoring
The clustering domain logic SHALL be properly encapsulated in a dedicated pack separate from the photos pack.

#### Scenario: Clustering pack exists
- **WHEN** the application initializes
- **THEN** a `packs/clustering` directory SHALL exist with proper Packwerk configuration
- **AND** the clustering pack SHALL declare a dependency on the photos pack

#### Scenario: Cluster model is namespaced correctly
- **WHEN** accessing cluster records
- **THEN** the model SHALL be accessible as `Clustering::Cluster`
- **AND** the model SHALL be located in `packs/clustering/app/models/clustering/cluster.rb`

#### Scenario: Photos reference clusters correctly
- **WHEN** a photo belongs to a cluster
- **THEN** the photo SHALL reference `Clustering::Cluster` via `belongs_to` association
- **AND** the cluster SHALL have `has_many :photos` association with counter cache

### Requirement: Cluster Listing
Users SHALL be able to view a summary of all existing clusters with their photo counts.

#### Scenario: List all clusters
- **WHEN** `Clustering::ListClusters.call` is invoked in the Rails console
- **THEN** a GLCommand::Context SHALL be returned with success: true
- **AND** all clusters SHALL be fetched from the database
- **AND** each cluster's ID, name, and photo count SHALL be printed to the console
- **AND** the context message SHALL contain a summary of results

#### Scenario: List clusters with no data
- **WHEN** `Clustering::ListClusters.call` is invoked and no clusters exist
- **THEN** the command SHALL succeed
- **AND** a message indicating "No clusters found" SHALL be displayed

### Requirement: Cluster Visual Inspection
Users SHALL be able to export a random sample of images from any cluster for visual review.

#### Scenario: View cluster with default sample size
- **WHEN** `Clustering::ViewCluster.call(cluster_id: 1)` is invoked
- **THEN** a GLCommand::Context SHALL be returned with success: true
- **AND** 10 random photos from the cluster SHALL be sampled
- **AND** a temporary directory at `/tmp/cluster_samples/cluster_1/` SHALL be created
- **AND** image files for the sampled photos SHALL be copied to the temporary directory
- **AND** the context SHALL contain the output path in `context.output_path`

#### Scenario: View cluster with custom sample size
- **WHEN** `Clustering::ViewCluster.call(cluster_id: 1, sample_size: 5)` is invoked
- **THEN** exactly 5 random photos SHALL be sampled
- **AND** 5 image files SHALL be copied to the temporary directory

#### Scenario: View cluster with invalid ID
- **WHEN** `Clustering::ViewCluster.call(cluster_id: 999)` is invoked with a non-existent cluster ID
- **THEN** a GLCommand::Context SHALL be returned with success: false
- **AND** the context errors SHALL contain "Cluster not found"

#### Scenario: View cluster without cluster_id
- **WHEN** `Clustering::ViewCluster.call` is invoked without cluster_id parameter
- **THEN** a GLCommand::Context SHALL be returned with success: false
- **AND** validation errors SHALL indicate cluster_id is required

### Requirement: Cluster Naming
Users SHALL be able to assign or change the human-readable name of any cluster.

#### Scenario: Rename cluster successfully
- **WHEN** `Clustering::RenameCluster.call(cluster_id: 1, new_name: "Cyberpunk Nights")` is invoked
- **THEN** a GLCommand::Context SHALL be returned with success: true
- **AND** the cluster's name attribute SHALL be updated to "Cyberpunk Nights"
- **AND** the change SHALL be persisted to the database
- **AND** the context message SHALL confirm the rename operation

#### Scenario: Rename cluster with invalid ID
- **WHEN** `Clustering::RenameCluster.call(cluster_id: 999, new_name: "Test")` is invoked with a non-existent cluster ID
- **THEN** a GLCommand::Context SHALL be returned with success: false
- **AND** the context errors SHALL contain "Cluster not found"

#### Scenario: Rename cluster without required parameters
- **WHEN** `Clustering::RenameCluster.call(cluster_id: 1)` is invoked without new_name
- **THEN** a GLCommand::Context SHALL be returned with success: false
- **AND** validation errors SHALL indicate new_name is required

#### Scenario: Rename cluster without cluster_id
- **WHEN** `Clustering::RenameCluster.call(new_name: "Test")` is invoked without cluster_id
- **THEN** a GLCommand::Context SHALL be returned with success: false
- **AND** validation errors SHALL indicate cluster_id is required

### Requirement: Command Validation
All console commands SHALL include proper input validation using ActiveModel::Validations.

#### Scenario: Required parameter validation
- **WHEN** any console command is invoked with missing required parameters
- **THEN** a GLCommand::Context SHALL be returned with success: false
- **AND** validation errors SHALL clearly indicate which parameters are missing

#### Scenario: Parameter type validation
- **WHEN** cluster_id parameter is provided with a non-integer value
- **THEN** the command SHALL handle the type coercion or validation error gracefully
- **AND** a meaningful error message SHALL be returned

### Requirement: Console Workflow Integration
The cluster management commands SHALL integrate seamlessly with the Rails console workflow.

#### Scenario: Chaining commands in console session
- **WHEN** a user runs `Clustering::ListClusters.call` followed by `Clustering::ViewCluster.call(cluster_id: 1)`
- **THEN** both commands SHALL execute independently
- **AND** each SHALL return its own context
- **AND** state SHALL not leak between commands

#### Scenario: Console output formatting
- **WHEN** `Clustering::ListClusters.call` prints cluster information
- **THEN** output SHALL be formatted as a readable table with aligned columns
- **AND** output SHALL include headers (ID, Name, Photos)
- **AND** output SHALL be printed directly to stdout for immediate visibility

### Requirement: Existing Clustering Functionality
The core clustering algorithm and rake task SHALL continue to function without disruption after refactoring.

#### Scenario: Generate clusters after refactoring
- **WHEN** `rails clustering:generate` is executed
- **THEN** clusters SHALL be generated using the K-Means algorithm
- **AND** cluster records SHALL be created in the database
- **AND** photos SHALL be assigned to clusters
- **AND** all functionality SHALL work identically to the pre-refactored state

#### Scenario: Clustering service maintains behavior
- **WHEN** `Clustering::ClusteringService` is invoked
- **THEN** DINO embeddings SHALL be processed
- **AND** K-Means clustering SHALL be applied
- **AND** cluster assignments SHALL be persisted
- **AND** counter caches SHALL be updated correctly
