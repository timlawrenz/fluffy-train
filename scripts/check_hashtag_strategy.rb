# Check Sarah's hashtag strategy

sarah = Persona.find_by!(name: 'sarah')

if sarah.hashtag_strategy.present?
  puts "✅ Sarah has hashtag strategy configured"
  puts ""
  puts "Strategy:"
  puts sarah.hashtag_strategy.inspect
else
  puts "⚠️  Sarah does not have hashtag strategy configured yet"
end
