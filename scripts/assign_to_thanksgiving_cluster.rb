# Assign imported photo to Thanksgiving cluster

persona = Persona.find_by!(name: 'sarah')
puts "✓ Persona: #{persona.name}"

# Create Thanksgiving cluster (current schema - no pillar_name yet)
cluster = Clustering::Cluster.find_or_create_by!(
  persona_id: persona.id,
  name: 'Thanksgiving Morning Coffee Nov 2024'
) do |c|
  c.size = 0
end
puts "✓ Cluster: #{cluster.name} (ID: #{cluster.id})"

# Find the photo we just imported
photo = Photo.where(persona_id: persona.id).where('filename LIKE ?', '%962260888107163%').order(created_at: :desc).first

if photo
  puts "✓ Found photo: #{photo.filename} (ID: #{photo.id})"
  
  # Assign to cluster
  photo.update!(cluster_id: cluster.id)
  cluster.update!(size: cluster.photos.count)
  
  puts "✓ Photo assigned to cluster"
  puts ""
  puts "📊 Photo Details:"
  puts "  - ID: #{photo.id}"
  puts "  - Filename: #{photo.filename}"
  puts "  - Cluster: #{cluster.name}"
  
  if photo.photo_analysis
    detected = photo.photo_analysis.detected_objects&.first(3)&.map { |o| o['label'] }&.join(', ')
    puts "  - Detected: #{detected || 'processing...'}"
    
    if photo.photo_analysis.caption
      puts ""
      puts "🤖 AI Generated Caption:"
      puts "   #{photo.photo_analysis.caption}"
    end
  else
    puts "  - Analysis: pending..."
  end
  
  puts ""
  puts "✅ READY TO SCHEDULE"
  puts "   Photo ID: #{photo.id}"
  puts "   Cluster: #{cluster.name}"
  puts "   Schedule for: Monday, Nov 11, 2024 at 9:00am ET"
else
  puts "❌ Photo not found"
  puts "   Recent photos:"
  persona.photos.order(created_at: :desc).limit(3).each do |p|
    puts "   - #{p.filename}"
  end
end
