# frozen_string_literal: true

require_relative 'photos/import'

class BulkImportPhotos < GLCommand::Callable
  requires :folder, persona: Persona
  returns :imported_count

  def call
    context.imported_count = 0
    all_file_paths = Dir.glob(File.join(folder, '**', '*.{jpg,png}'), File::FNM_CASEFOLD)
    initial_count = Photo.count
    all_file_paths.each do |path|
      puts "Importing #{path}"
      Photos::Import.call!(path: path, persona: persona)
    end

    context.imported_count = Photo.count - initial_count
  end
end
