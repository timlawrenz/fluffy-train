# frozen_string_literal: true

namespace :instagram do
  desc 'Test the full Instagram scheduling workflow'
  task test_schedule: :environment do
    puts 'Starting Instagram scheduling test...'

    # 1. Find the Persona
    persona = Personas.find_by_name(name: 'Sarah')
    unless persona
      puts 'Error: Could not find the "Sarah" persona. Please ensure it exists.'
      exit 1
    end
    puts "Found persona: #{persona.name}"

    # 2. Find an Unscheduled Photo
    # First, ensure the persona has photos associated with it.
    unless persona.photos.any?
      puts "Error: The '#{persona.name}' persona has no photos. Please import some first."
      exit 1
    end

    photo = Scheduling.unscheduled_for_persona(persona: persona).sample
    unless photo
      puts 'Error: Could not find an unscheduled photo for this persona. All photos may be scheduled.'
      exit 1
    end
    puts "Selected photo to schedule: #{photo.path}"

    # 3. Ensure the photo has an ActiveStorage attachment
    unless photo.image.attached?
      puts 'Attaching image to photo record...'
      photo.image.attach(io: File.open(photo.path), filename: File.basename(photo.path))
    end

    # 4. Schedule the Post
    caption = "Testing the new Instagram API integration! This is a test post from the fluffy-train project. #{Time.now.to_i}"
    puts "Attempting to schedule post with caption: \"#{caption}\""

    result = Scheduling.schedule_post(photo: photo, persona: persona, caption: caption)

    # 5. Report the Outcome
    if result.success?
      puts "\n✅ Post scheduled successfully!"
      puts "   Instagram Post ID: #{result.post.external_post_id}"
    else
      puts "\n❌ Failed to schedule post."
      puts "   Errors: #{result.errors.full_messages.join(', ')}"
    end
  end
end
