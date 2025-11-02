## 1. Refactoring
- [x] 1.1 Create `packs/clustering` pack structure with `package.yml`
- [x] 1.2 Declare dependency on `packs/photos` in clustering package
- [x] 1.3 Move `Photos::Cluster` model to `Clustering::Cluster`
- [x] 1.4 Move `Photos::ClusteringService` to `Clustering::ClusteringService`
- [x] 1.5 Move `clustering:generate` rake task to `packs/clustering/lib/tasks/`
- [x] 1.6 Update `Photos::Photo` model to reference `Clustering::Cluster`
- [x] 1.7 Move and update model specs to `packs/clustering/spec/models/`
- [x] 1.8 Move and update service specs to `packs/clustering/spec/services/`
- [x] 1.9 Move and update rake task specs to `packs/clustering/spec/tasks/`

## 2. Console Commands Implementation
- [x] 2.1 Implement `Clustering::ListClusters` command
  - [x] 2.1.1 Fetch all clusters with photo counts
  - [x] 2.1.2 Format and print console table output
  - [x] 2.1.3 Return GLCommand::Context with success message
- [x] 2.2 Implement `Clustering::ViewCluster` command
  - [x] 2.2.1 Add validations for cluster_id (required)
  - [x] 2.2.2 Find cluster and handle not found case
  - [x] 2.2.3 Sample random photos (default: 10, configurable)
  - [x] 2.2.4 Create temporary directory (`/tmp/cluster_samples/cluster_<id>`)
  - [x] 2.2.5 Copy sample image files to temporary directory
  - [x] 2.2.6 Return context with output_path
- [x] 2.3 Implement `Clustering::RenameCluster` command
  - [x] 2.3.1 Add validations for cluster_id and new_name (both required)
  - [x] 2.3.2 Find cluster and handle not found case
  - [x] 2.3.3 Update cluster name attribute
  - [x] 2.3.4 Return context with confirmation message

## 3. Testing
- [x] 3.1 Write unit tests for `Clustering::ListClusters`
  - [x] 3.1.1 Test successful cluster listing
  - [x] 3.1.2 Test console output formatting (stub puts)
- [x] 3.2 Write unit tests for `Clustering::ViewCluster`
  - [x] 3.2.1 Test successful sample export
  - [x] 3.2.2 Test cluster not found error
  - [x] 3.2.3 Test validation errors (missing cluster_id)
  - [x] 3.2.4 Mock FileUtils operations
- [x] 3.3 Write unit tests for `Clustering::RenameCluster`
  - [x] 3.3.1 Test successful cluster rename
  - [x] 3.3.2 Test cluster not found error
  - [x] 3.3.3 Test validation errors (missing parameters)
  - [x] 3.3.4 Test database update persistence

## 4. Documentation
- [x] 4.1 Update pack README for `packs/clustering`
- [x] 4.2 Document console workflow examples
- [x] 4.3 Add usage examples to command classes
