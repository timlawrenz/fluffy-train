# frozen_string_literal: true

class CreatePhoto < GLCommand::Callable
  requires :path, persona: Persona
  returns :photo

  def call
    @photo = Photo.find_or_initialize_by(path: path)
    @created_in_command = @photo.new_record?

    create_new_photo if @created_in_command

    if @photo.persisted?
      context.photo = @photo
    else
      stop_and_fail!(@photo.errors.full_messages.to_sentence, no_notify: true)
    end
  end

  def rollback
    @photo&.destroy if @created_in_command
  end

  private

  def create_new_photo
    @photo.persona = persona

    return unless @photo.save

    # Attach the image file using ActiveStorage if the photo saves successfully
    attach_image_file
    GenerateEmbeddingJob.perform_later(@photo.id)
  end

  def attach_image_file
    return unless File.exist?(path)

    File.open(path) do |file|
      @photo.image.attach(
        io: file,
        filename: File.basename(path)
      )
    end
  end
end
