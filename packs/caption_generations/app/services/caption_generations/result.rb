# frozen_string_literal: true

module CaptionGenerations
  class Result
    attr_reader :text, :metadata, :variations

    def initialize(text:, metadata: {}, variations: [])
      @text = text
      @metadata = metadata
      @variations = variations
    end
  end
end
