#!/usr/bin/env ruby
# Import and prepare Thanksgiving Post #1
# Usage: PHOTO_PATH=/path/to/photo.jpg bin/rails runner scripts/import_thanksgiving_nov11.rb

puts "🍂 Importing Thanksgiving Post #1: Morning Coffee (Nov 11)"
puts "=" * 60

PHOTO_PATH = ENV['PHOTO_PATH'] || raise("Set PHOTO_PATH environment variable")
SCHEDULED_TIME = "2024-11-11 09:00:00 EST"
CAPTION = "Something about these slower November mornings ☕ The way the light hits differently this time of year"

persona = Persona.find_by!(name: 'sarah')
puts "✓ Persona: #{persona.name}"

puts "\n📸 Importing: #{PHOTO_PATH}"
photo = Photo.create!(
  persona: persona,
  image: File.open(PHOTO_PATH),
  filename: File.basename(PHOTO_PATH)
)
puts "✓ Photo ID: #{photo.id}"

cluster = Clustering::Cluster.find_or_create_by!(
  persona: persona,
  name: 'Thanksgiving Morning Coffee Nov 2024'
) do |c|
  c.pillar_name = 'Seasonal & Events'
  c.size = 0
end

photo.update!(cluster: cluster)
cluster.increment!(:size)
puts "✓ Cluster: #{cluster.name}"

puts "\n✍️  Caption: #{CAPTION}"
puts "\n📅 Schedule for: #{SCHEDULED_TIME}"
puts "\n✅ Ready to schedule!"
