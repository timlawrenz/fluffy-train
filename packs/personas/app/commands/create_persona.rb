# frozen_string_literal: true

class CreatePersona < GLCommand::Callable
  requires :name
  returns :persona

  def call
    @persona = Persona.new(name: name)

    if @persona.save
      context.persona = @persona
    else
      stop_and_fail!(@persona.errors.full_messages.to_sentence, no_notify: true)
    end
  end

  def rollback
    @persona&.destroy
  end
end
