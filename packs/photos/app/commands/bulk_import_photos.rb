# frozen_string_literal: true

require_relative 'photos/import'

class BulkImportPhotos < GLCommand::Callable
  requires :folder, persona: Persona
  returns :imported_count, :skipped_count, :failed_count, :import_errors

  def call
    context.imported_count = 0
    context.skipped_count = 0
    context.failed_count = 0
    context.import_errors = []
    
    all_file_paths = Dir.glob(File.join(folder, '**', '*.{jpg,png}'), File::FNM_CASEFOLD)
    
    all_file_paths.each do |path|
      if Photo.exists?(path: path)
        puts "Skipping #{path} (already imported)"
        context.skipped_count += 1
        next
      end

      puts "Importing #{path}"
      result = Photos::Import.call(path: path, persona: persona)
      
      if result.success?
        context.imported_count += 1
      else
        context.failed_count += 1
        error_msg = result.full_error_message || 'Unknown error'
        context.import_errors << { path: path, error: error_msg }
        puts "  Failed: #{error_msg}"
      end
    end
  end
end
