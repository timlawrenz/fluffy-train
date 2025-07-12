# frozen_string_literal: true

class CreatePhoto < GLCommand::Callable
  requires :path
  requires persona: Persona
  returns :photo

  def call
    @photo = Photo.new(path: path, persona: persona)

    if @photo.save
      context.photo = @photo
    else
      stop_and_fail!(@photo.errors.full_messages.to_sentence, no_notify: true)
    end
  end

  def rollback
    @photo&.destroy
  end
end
