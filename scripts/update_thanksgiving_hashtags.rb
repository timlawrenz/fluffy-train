# Update Thanksgiving post with intelligent hashtags

post = Scheduling::Post.find(78)
photo = post.photo
sarah = post.persona

puts "📝 Updating Thanksgiving Post #1 with Intelligent Hashtags"
puts "=" * 60

# Generate hashtags
result = HashtagGenerations::Generator.generate(
  photo: photo,
  persona: sarah,
  cluster: photo.cluster,
  count: 10
)

# Create full caption with hashtags
base_caption = post.caption
hashtag_line = "\n\n" + result[:hashtags].join(' ')
full_caption = base_caption + hashtag_line

# Update post
post.update!(caption: full_caption)

puts "✅ Post Updated!"
puts ""
puts "Caption:"
puts post.caption
puts ""
puts "Generated Hashtags:"
result[:hashtags].each_with_index do |tag, i|
  puts "   #{i+1}. #{tag}"
end
puts ""
puts "🎯 Post ready for Monday, Nov 11 at 9:00am ET"
