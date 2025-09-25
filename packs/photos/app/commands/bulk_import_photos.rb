# frozen_string_literal: true

require_relative 'photos/import'

class BulkImportPhotos < GLCommand::Callable
  requires :folder, persona: Persona
  returns :imported_count

  def call
    unless Dir.exist?(folder)
      stop_and_fail!("Folder does not exist: #{folder}", no_notify: true)
      return
    end

    all_file_paths = Dir.glob(File.join(folder, '**', '*.{jpg,png}'), File::FNM_CASEFOLD)

    if all_file_paths.empty?
      context.imported_count = 0
      return
    end

    initial_count = Photo.count

    all_file_paths.each do |path|
      Photos::Import.call!(path: path, persona: persona)
    end

    context.imported_count = Photo.count - initial_count
  end
end
