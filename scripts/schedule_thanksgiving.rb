# Schedule Thanksgiving Post #1

photo = Photo.find(24727)
sarah = Persona.find_by!(name: 'sarah')

caption = 'Something about these slower November mornings ☕ The way the light hits differently this time of year'

# Schedule for Monday, November 11, 2024 at 9:00am ET
scheduled_time = Time.zone.parse('2024-11-11 09:00:00 EST')

puts "Scheduling Thanksgiving Post #1..."
puts "Photo ID: #{photo.id}"
puts "Scheduled for: #{scheduled_time}"

# Create scheduled post
post = Scheduling::Post.create!(
  persona: sarah,
  photo: photo,
  caption: caption,
  scheduled_at: scheduled_time
)

puts ""
puts "✅ POST SCHEDULED!"
puts "Post ID: #{post.id}"
puts "Status: #{post.status}"
puts "Scheduled at: #{post.scheduled_at}"
puts ""
puts "🎯 Post will go live: Monday, November 11, 2024 at 9:00am ET"
