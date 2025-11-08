# Simple script to assign Thanksgiving photo to cluster

# Find Sarah
sarah = Persona.find_by!(name: 'sarah')
puts "✓ Found persona: sarah"

# Find or create cluster
cluster = Clustering::Cluster.find_or_create_by!(name: 'Thanksgiving Morning Coffee Nov 2024') do |c|
  c.photos_count = 0
  c.status = 0
end
puts "✓ Cluster: #{cluster.name} (ID: #{cluster.id})"

# Find the imported photo
photo = sarah.photos.where('path LIKE ?', '%962260888107163%').order(created_at: :desc).first

if photo
  puts "✓ Found photo ID: #{photo.id}"
  photo.update!(cluster_id: cluster.id)
  cluster.update!(photos_count: cluster.photos_count + 1)
  puts "✅ Photo assigned to cluster!"
  puts ""
  puts "Next: Schedule for Monday Nov 11, 9am ET"
else
  puts "❌ Photo not found. Recent photos:"
  sarah.photos.order(created_at: :desc).limit(3).each do |p|
    puts "  - #{p.path}"
  end
end
