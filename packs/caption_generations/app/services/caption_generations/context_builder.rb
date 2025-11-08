# frozen_string_literal: true

module CaptionGenerations
  class ContextBuilder
    def self.build(photo:, cluster: nil)
      new(photo: photo, cluster: cluster).build
    end

    def initialize(photo:, cluster: nil)
      @photo = photo
      @cluster = cluster
    end

    def build
      {
        cluster_name: cluster_name,
        image_description: image_description
      }
    end

    private

    def cluster_name
      @cluster&.name || @photo.cluster&.name
    end

    def image_description
      @photo.photo_analysis&.caption
    end
  end
end
