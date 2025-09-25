# frozen_string_literal: true

require 'gl_command'
require_relative '../create_photo'
require_relative 'analyse_photo'

module Photos
  class Import < GLCommand::Chainable
    requires :path, persona: Persona
    returns :photo, :photo_analysis

    chain CreatePhoto,
          Photos::AnalysePhoto
  end
end
