# Adding New Photos Guide

This guide explains how to add new photos to fluffy-train and prepare them for posting.

## Prerequisites

- Photos should be in a format supported by Instagram (JPG, PNG)
- Photos should be in a directory accessible to the application
- Recommended: Photos should be organized in a folder structure

## Step 1: Import Photos

### Using Rake Task (Recommended)

```bash
# Import all photos from a directory
bundle exec rails photos:import[sarah,/path/to/photos]

# Example:
bundle exec rails photos:import[sarah,/home/user/new-photos]
```

This will:
- Import all images from the specified directory
- Create `Photo` records in the database
- Attach images to ActiveStorage
- Skip already imported photos (based on path)

### Using Rails Console (Advanced)

```ruby
# Start console
bundle exec rails console

# Import photos manually
persona = Persona.find_by(name: 'sarah')
photo_dir = '/path/to/photos'

Dir.glob("#{photo_dir}/**/*.{jpg,jpeg,png}").each do |path|
  next if Photo.exists?(path: path)
  
  photo = Photo.create!(
    persona: persona,
    path: path
  )
  
  photo.image.attach(
    io: File.open(path),
    filename: File.basename(path)
  )
  
  puts "Imported: #{path}"
end
```

### Verify Import

```ruby
# Check newly imported photos
persona = Persona.find_by(name: 'sarah')
recent_photos = persona.photos.order(created_at: :desc).limit(10)

recent_photos.each do |photo|
  puts "#{photo.id}: #{photo.path}"
  puts "  Created: #{photo.created_at}"
  puts "  Has image: #{photo.image.attached?}"
  puts ""
end
```

## Step 2: Analyze Photos (Optional but Recommended)

Photo analysis provides aesthetic scores and captions used by the Content Strategy Engine.

### Analyze All Unanalyzed Photos

```bash
# Run photo analysis on all photos without analysis
bundle exec rails photos:analyze[sarah]
```

### Analyze Specific Photos

```ruby
# In Rails console
persona = Persona.find_by(name: 'sarah')

# Find photos without analysis
unanalyzed = Photo
  .where(persona: persona)
  .left_joins(:photo_analysis)
  .where(photo_analyses: { id: nil })

puts "Found #{unanalyzed.count} photos without analysis"

# Analyze them (if you have the analysis service set up)
# unanalyzed.each do |photo|
#   PhotoAnalysis.create!(
#     photo: photo,
#     aesthetic_score: 0.75,  # Would come from actual analysis
#     sharpness_score: 0.80,
#     exposure_score: 0.70
#   )
# end
```

## Step 3: Cluster Photos

Clustering groups similar photos together, which is essential for the Content Strategy Engine.

### Run Clustering

```bash
# Cluster all photos for a persona
bundle exec rails clustering:cluster_photos[sarah]
```

This will:
- Generate embeddings for photos
- Use DBSCAN algorithm to find similar photos
- Create clusters and assign photos to them
- Update cluster photo counts

### Check Clustering Results

```ruby
# In Rails console
persona = Persona.find_by(name: 'sarah')

# View clusters
Clustering::Cluster.joins(:photos)
  .where(photos: { persona: persona })
  .distinct
  .order(photos_count: :desc)
  .each do |cluster|
    puts "#{cluster.name} (#{cluster.photos_count} photos)"
    
    # Show a few sample photos
    cluster.photos.where(persona: persona).limit(3).each do |photo|
      puts "  - #{File.basename(photo.path)}"
    end
    puts ""
  end

# Check unclustered photos
unclustered = Photo.where(persona: persona, cluster_id: nil).count
puts "\nUnclustered photos: #{unclustered}"
```

### Manual Cluster Assignment (Optional)

If photos weren't automatically clustered or you want to reorganize:

```ruby
# Create a new cluster
cluster = Clustering::Cluster.create!(
  name: 'Sunset Photos',
  status: 'active'
)

# Find photos to assign
photos = Photo.where(persona: persona)
  .where("path LIKE ?", "%sunset%")
  .where(cluster_id: nil)

# Assign them
photos.update_all(cluster_id: cluster.id)
cluster.update!(photos_count: photos.count)

puts "Assigned #{photos.count} photos to '#{cluster.name}'"
```

## Step 4: Review New Photos

### View Recently Added Photos

```ruby
# Photos added in last 24 hours
recent = Photo
  .where(persona: persona)
  .where('created_at >= ?', 24.hours.ago)
  .includes(:cluster, :photo_analysis)
  .order(created_at: :desc)

puts "Recently added photos: #{recent.count}"
recent.each do |photo|
  puts "\n#{photo.id}: #{File.basename(photo.path)}"
  puts "  Cluster: #{photo.cluster&.name || 'Not clustered'}"
  puts "  Aesthetic: #{photo.photo_analysis&.aesthetic_score || 'Not analyzed'}"
  puts "  Posted: #{photo.posted? ? 'Yes' : 'No'}"
end
```

### View Unposted Photos by Cluster

```ruby
# See what's available to post
Clustering::Cluster.joins(:photos)
  .where(photos: { persona: persona })
  .distinct
  .each do |cluster|
    unposted = cluster.unposted_photos.where(persona: persona).count
    puts "#{cluster.name}: #{unposted} unposted photos"
  end
```

## Step 5: Test Content Strategy

Before going live, test that the strategy can select from your new photos:

```ruby
# Test selection
result = ContentStrategy::SelectNextPost.new(persona: persona).call

if result[:success]
  puts "✅ Strategy can select photos"
  puts "Selected: #{result[:photo].path}"
  puts "From cluster: #{result[:cluster].name}"
  puts "Hashtags: #{result[:hashtags].join(' ')}"
else
  puts "❌ Error: #{result[:error]}"
end
```

## Workflow Summary

```bash
# 1. Import photos
bundle exec rails photos:import[sarah,/path/to/new/photos]

# 2. Analyze photos (if available)
bundle exec rails photos:analyze[sarah]

# 3. Cluster photos
bundle exec rails clustering:cluster_photos[sarah]

# 4. Check clusters
bundle exec rails clustering:list_clusters[sarah]

# 5. View content strategy status
bundle exec rails content_strategy:show[sarah]

# 6. Ready to post!
bundle exec rails scheduling:post_with_strategy[sarah]
```

## Maintenance

### Re-clustering Photos

If you've added many new photos or want to reorganize:

```bash
# Re-run clustering (will reassign all photos)
bundle exec rails clustering:cluster_photos[sarah]

# Reset strategy state to pick from new clusters
bundle exec rails content_strategy:reset[sarah]
```

### Checking Photo Quality

```ruby
# Find photos with low aesthetic scores
low_quality = Photo
  .joins(:photo_analysis)
  .where(persona: persona)
  .where('photo_analyses.aesthetic_score < ?', 0.5)
  .order('photo_analyses.aesthetic_score ASC')

puts "Low quality photos: #{low_quality.count}"
low_quality.limit(10).each do |photo|
  puts "#{photo.id}: #{photo.path} (#{photo.photo_analysis.aesthetic_score})"
end

# You might want to exclude these from posting
```

### Removing Photos

```ruby
# Remove a photo (also removes from posts, analysis)
photo = Photo.find(12345)
photo.destroy

# Remove all photos from a cluster
cluster = Clustering::Cluster.find_by(name: 'Bad Photos')
cluster.photos.where(persona: persona).destroy_all
```

## Tips

1. **Batch imports:** Import photos in batches (100-500 at a time) for better performance
2. **Photo quality:** Pre-filter low-quality photos before importing
3. **Consistent naming:** Use consistent file naming for easier organization
4. **Backup:** Keep original photos backed up separately
5. **Test clustering:** After adding many new photos, check cluster quality
6. **Storage space:** Monitor ActiveStorage space usage (photos are stored in cloud/local)

## Troubleshooting

### Photos Not Importing

```ruby
# Check file permissions
Dir.glob("/path/to/photos/*.jpg").each do |path|
  puts "#{path}: #{File.readable?(path) ? 'OK' : 'CANNOT READ'}"
end

# Check if already imported
Photo.where(path: '/path/to/photo.jpg').exists?
```

### Photos Not Clustering

```ruby
# Check if photos have embeddings
photos_without_embeddings = Photo
  .where(persona: persona)
  .where(embedding: nil)
  .count

puts "Photos without embeddings: #{photos_without_embeddings}"

# Re-run embedding generation if needed
# (This requires the embedding service to be configured)
```

### New Photos Not Being Selected

```ruby
# Check if photos are unposted
photo = Photo.find(12345)
puts "Posted: #{photo.posted?}"

# Check if in a cluster
puts "Cluster: #{photo.cluster&.name || 'Not clustered'}"

# Check if cluster has unposted photos
if photo.cluster
  puts "Unposted in cluster: #{photo.cluster.unposted_photos.count}"
end
```

## Next Steps

- [Review Clusters](./docs/04b-cluster-management.md) - Organize and name clusters
- [Daily Posting Guide](./docs/daily-posting-guide.md) - Start posting
- [Content Strategy](./docs/04c-content-strategy-engine.md) - Configure strategies
