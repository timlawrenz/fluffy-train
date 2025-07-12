# frozen_string_literal: true

class CreatePhoto < GLCommand::Callable
  requires :path, persona: Persona
  returns :photo

  def call
    @photo = Photo.find_or_initialize_by(path: path)
    @created_in_command = @photo.new_record?

    if @created_in_command
      @photo.persona = persona
      @photo.save
    end

    if @photo.persisted?
      context.photo = @photo
    else
      stop_and_fail!(@photo.errors.full_messages.to_sentence, no_notify: true)
    end
  end

  def rollback
    @photo&.destroy if @created_in_command
  end
end
