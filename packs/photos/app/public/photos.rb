# frozen_string_literal: true

require_relative '../commands/photos/import'

# The public API for the photos pack.
module Photos
  # Finds a Photo by its ID.
  #
  # @param id [Integer] the ID of the Photo to find.
  # @return [Photo, nil] the found Photo, or nil if not found.
  def self.find(id)
    Photo.find_by(id: id)
  end

  # Creates a new Photo and analyzes it.
  #
  # @param path [String] the path of the new photo.
  # @param persona [Persona] the persona this photo belongs to.
  # @return [GLCommand::Context] the result of the Photos::Import command.
  def self.create(path:, persona:)
    Photos::Import.call(path: path, persona: persona)
  end

  # Bulk imports photos from a folder for a specific persona.
  #
  # @param folder [String] the path to the folder.
  # @param persona [Persona] the persona these photos belong to.
  # @return [GLCommand::Context] the result of the BulkImportPhotos command.
  def self.bulk_import(folder:, persona:)
    BulkImportPhotos.call(folder: folder, persona: persona)
  end

  # Generates and saves an embedding for a photo.
  #
  # @param photo [Photo] the photo to process.
  # @return [GLCommand::Context] the result of the GenerateEmbedding command.
  def self.generate_embedding(photo:)
    GenerateEmbedding.call(photo: photo)
  end
end
