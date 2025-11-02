# Clustering Pack

This pack manages photo clustering using machine learning algorithms to group visually similar images.

## Overview

The clustering pack provides:
- K-Means clustering on DINO embeddings
- Console-based cluster management and curation tools
- Cluster naming and organization capabilities

## Core Components

### Models

#### `Clustering::Cluster`
Represents a group of visually similar photos.

**Attributes:**
- `name` (string) - Human-readable cluster name
- `status` (integer) - Status enum (0 = active)
- `photos_count` (integer) - Counter cache for associated photos

**Associations:**
- `has_many :photos` - Photos belonging to this cluster

### Services

#### `Clustering::ClusteringService`
Performs K-Means clustering on photo DINO embeddings.

**Usage:**
```ruby
service = Clustering::ClusteringService.new(k_clusters: 20)
result = service.call

if result[:success]
  puts "Clustered #{result[:photos_processed]} photos into #{result[:clusters_created]} clusters"
end
```

### Console Commands

#### `Clustering::ListClusters`
Lists all clusters with their photo counts.

**Usage:**
```ruby
Clustering::ListClusters.call
```

**Output:**
```
ID    | Name                           | Photos    
--------------------------------------------------
1     | Cyberpunk Nights              | 42        
2     | Nature Landscapes             | 87        
3     | (unnamed)                     | 15        
```

#### `Clustering::ViewCluster`
Exports a random sample of photos from a cluster for visual inspection.

**Usage:**
```ruby
result = Clustering::ViewCluster.call(cluster_id: 1, sample_size: 10)
puts result.output_path if result.success?
# => "/tmp/cluster_samples/cluster_1"
```

**Parameters:**
- `cluster_id` (required) - ID of the cluster to view
- `sample_size` (optional, default: 10) - Number of photos to sample

#### `Clustering::RenameCluster`
Assigns a human-readable name to a cluster.

**Usage:**
```ruby
result = Clustering::RenameCluster.call(
  cluster_id: 1, 
  new_name: "Cyberpunk Nights"
)
puts result.message if result.success?
# => "Successfully renamed cluster 1 to 'Cyberpunk Nights'"
```

**Parameters:**
- `cluster_id` (required) - ID of the cluster to rename
- `new_name` (required) - New name for the cluster

## Rake Tasks

### `clustering:generate`
Generates clusters for all unclustered photos using K-Means clustering.

**Usage:**
```bash
rails clustering:generate
```

This task:
1. Finds all photos with DINO embeddings that don't belong to a cluster
2. Applies K-Means clustering algorithm
3. Creates cluster records
4. Assigns photos to their respective clusters

**Configuration:**
- Default number of clusters: 20
- Can be customized via service initialization

## Console Workflow Example

Here's a typical workflow for managing clusters via Rails console:

```ruby
# 1. Generate clusters for unclustered photos
Rake::Task['clustering:generate'].invoke

# 2. List all clusters to see what was created
Clustering::ListClusters.call

# 3. View sample images from a cluster to understand its theme
result = Clustering::ViewCluster.call(cluster_id: 3, sample_size: 10)
# Open file browser to /tmp/cluster_samples/cluster_3

# 4. Rename the cluster based on visual inspection
Clustering::RenameCluster.call(
  cluster_id: 3, 
  new_name: "Urban Street Photography"
)

# 5. Verify the rename
Clustering::ListClusters.call
```

## Dependencies

This pack depends on:
- `packs/photos` - For accessing Photo model and associations

## Testing

Run specs for this pack:
```bash
rspec packs/clustering/spec
```

Test coverage includes:
- Model associations and validations
- Clustering algorithm behavior
- Console command functionality
- Rake task integration
