# frozen_string_literal: true

# The public API for the photos pack.
module Photos
  # Finds a Photo by its ID.
  #
  # @param id [Integer] the ID of the Photo to find.
  # @return [Photo, nil] the found Photo, or nil if not found.
  def self.find(id)
    Photo.find_by(id: id)
  end

  # Creates a new Photo.
  #
  # @param path [String] the path of the new photo.
  # @param persona [Persona] the persona this photo belongs to.
  # @return [GLCommand::Context] the result of the CreatePhoto command.
  def self.create(path:, persona:)
    CreatePhoto.call(path: path, persona: persona)
  end
end
