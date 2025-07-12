# frozen_string_literal: true

namespace :photos do
  desc "Bulk import photos from a folder for a given persona. Usage: rails \"photos:bulk_import[<persona_name>,<folder_path>]\""
  task :bulk_import, [:persona_name, :folder_path] => :environment do |_, args|
    if args[:persona_name].blank?
      puts "Error: Persona name must be provided."
      puts "Usage: rails \"photos:bulk_import[<persona_name>,<folder_path>]\""
      exit 1
    end

    if args[:folder_path].blank?
      puts "Error: Folder path must be provided."
      puts "Usage: rails \"photos:bulk_import[<persona_name>,<folder_path>]\""
      exit 1
    end

    persona = Persona.find_by(name: args[:persona_name])
    unless persona
      puts "Error: Persona with name '#{args[:persona_name]}' not found."
      exit 1
    end

    puts "Importing photos from '#{args[:folder_path]}' for persona '#{persona.name}'..."

    result = Photos.bulk_import(folder: args[:folder_path], persona: persona)

    if result.success?
      puts "Successfully imported #{result.imported_count} new photo(s)."
    else
      puts "Failed to import photos: #{result.full_error_message}"
      exit 1
    end
  end
end
