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
        image_description: image_description,
        photo_analysis: photo_analysis_data,
        cluster_data: cluster_data
      }
    end

    private

    def cluster_name
      @cluster&.name || @photo.cluster&.name
    end

    def image_description
      @photo.photo_analysis&.caption
    end

    def photo_analysis_data
      return nil unless @photo.photo_analysis

      {
        aesthetic_score: @photo.photo_analysis.aesthetic_score&.round(1),
        detected_objects: @photo.photo_analysis.detected_objects&.map do |obj|
          {
            label: obj['label'],
            confidence: obj['confidence']&.round(2)
          }
        end&.first(5) # Top 5 most confident objects
      }.compact
    end

    def cluster_data
      cluster = @cluster || @photo.cluster
      return nil unless cluster

      {
        name: cluster.name,
        ai_prompt: cluster.ai_prompt
      }.compact
    end
  end
end
