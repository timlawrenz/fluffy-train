# Photos Pack

This pack is responsible for managing photos and their association with personas.

## Public API

The public API for this pack is defined in the `Photos` module. To interact with photos from outside this pack, you should use the methods provided by this module.

### `Photos.find(id)`

Finds a single photo by its ID.

**Parameters:**

*   `id` (`Integer`): The unique ID of the photo.

**Returns:**

*   The `Photo` object if found.
*   `nil` if no photo with the given ID exists.

**Example:**

```ruby
photo = Photos.find(1)
if photo
  puts "Found photo at path: #{photo.path}"
else
  puts 'Photo not found.'
end
```

### `Photos.create(path:, persona:)`

Creates a new photo record and associates it with a persona.

**Parameters:**

*   `path` (`String`): The file system path to the photo. Must be unique.
*   `persona` (`Persona`): The persona object to which this photo belongs.

**Returns:**

A `GLCommand::Context` object.

*   On success, the context will be successful (`context.success?` is `true`), and `context.photo` will contain the newly created `Photo` record.
*   On failure (e.g., validation error), the context will be a failure (`context.success?` is `false`), and `context.full_error_message` will contain a description of the error.

**Example:**

```ruby
persona = Personas.find(1)
result = Photos.create(path: '/path/to/my/photo.jpg', persona: persona)
if result.success?
  puts "Successfully created photo: #{result.photo.path}"
else
  puts "Failed to create photo: #{result.full_error_message}"
end
```

### `Photos.bulk_import(folder:, persona:)`

Recursively finds all files in a given folder and creates `Photo` records for them, associating them with the given persona. It intelligently skips files that have already been imported.

**Parameters:**

*   `folder` (`String`): The absolute path to the folder containing the photos to import.
*   `persona` (`Persona`): The persona object to which the imported photos will belong.

**Returns:**

A `GLCommand::Context` object.

*   On success, `context.imported_count` will contain the number of newly imported photos.
*   On failure (e.g., folder not found), `context.full_error_message` will contain a description of the error.

**Example:**

```ruby
persona = Personas.find(1)
result = Photos.bulk_import(folder: '/path/to/album', persona: persona)
if result.success?
  puts "Successfully imported #{result.imported_count} new photos."
else
  puts "Failed to import photos: #{result.full_error_message}"
end
```

### `Photos.generate_embedding(photo:)`

Generates and saves a vector embedding for a given photo by calling an external `image_embed` service. The operation is idempotent; if an embedding already exists for the photo, it will not be regenerated.

**Parameters:**

*   `photo` (`Photo`): The photo object to generate an embedding for.

**Returns:**

A `GLCommand::Context` object.

*   On success, `context.photo` will contain the `Photo` record, now with its `embedding` attribute populated.
*   On failure (e.g., the photo file is not found, or the external service is unavailable), the context will be a failure, and `context.full_error_message` will describe the error.

**Example:**

```ruby
photo = Photos.find(1)
result = Photos.generate_embedding(photo: photo)
if result.success?
  puts "Embedding generated for #{result.photo.path}"
else
  puts "Failed to generate embedding: #{result.full_error_message}"
end
```
