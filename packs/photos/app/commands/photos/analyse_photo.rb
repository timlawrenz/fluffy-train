# frozen_string_literal: true

require 'gl_command'
require_relative 'analyse/sharpness'
require_relative 'analyse/exposure'
require_relative 'analyse/aesthetics'
require_relative 'analyse/object_detection'
require_relative 'analyse/save_results'

module Photos
  class AnalysePhoto < GLCommand::Chainable
    requires :photo
    returns :photo_analysis

    chain Photos::Analyse::Sharpness,
          Photos::Analyse::Exposure,
          Photos::Analyse::Aesthetics,
          Photos::Analyse::ObjectDetection,
          Photos::Analyse::SaveResults
  end
end
