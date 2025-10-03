# frozen_string_literal: true

namespace :scheduling do
  desc 'Posts the next best photo using the Curator\'s Choice strategy'
  task :post_next_best, [:persona_name] => :environment do |_, args|
    persona = if args[:persona_name].present?
                Personas.find_by_name(name: args[:persona_name])
              else
                Personas.list.first
              end

    unless persona
      if args[:persona_name].present?
        puts "Error: Persona with name '#{args[:persona_name]}' not found."
      else
        puts 'Error: No personas found. Please create a persona first.'
      end
      exit 1
    end

    puts "Selecting next best photo for persona: #{persona.name}"

    result = Scheduling::Strategies::CuratorsChoice.call(persona: persona)

    if result.success?
      if result.selected_photo
        puts "Successfully selected and posted photo: #{result.selected_photo.id}"
      else
        puts "No unposted photos available for persona: #{persona.name}"
      end
    else
      puts "Failed to post photo: #{result.errors.join(', ')}"
      exit 1
    end
  end
end
