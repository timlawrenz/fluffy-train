# frozen_string_literal: true

class BulkImportPhotos < GLCommand::Callable
  requires :folder, persona: Persona
  returns :imported_count

  def call
    unless Dir.exist?(folder)
      stop_and_fail!("Folder does not exist: #{folder}", no_notify: true)
      return
    end

    all_file_paths = Dir.glob(File.join(folder, '**', '*')).select { |f| File.file?(f) }

    if all_file_paths.empty?
      context.imported_count = 0
      return
    end

    existing_paths = Photo.where(path: all_file_paths).pluck(:path)
    new_paths = all_file_paths - existing_paths

    if new_paths.empty?
      context.imported_count = 0
      return
    end

    photos_to_insert = new_paths.map do |path|
      {
        persona_id: persona.id,
        path: path,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    result = Photo.insert_all(photos_to_insert)
    context.imported_count = result.count
  rescue StandardError => e
    stop_and_fail!(e.message)
  end
end
