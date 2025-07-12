# frozen_string_literal: true

class CreatePersona
  include GLCommand::Base

  def initialize(name:)
    @name = name
    @persona = Persona.new(name: @name)
  end

  def call
    if @persona.save
      success!(@persona)
    else
      failure!(@persona.errors)
    end
  end

  def rollback
    return unless success? && result&.persisted?

    result.destroy
  end
end
