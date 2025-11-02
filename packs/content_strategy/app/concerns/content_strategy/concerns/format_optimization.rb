module ContentStrategy
  module Concerns
    module FormatOptimization
      extend ActiveSupport::Concern

      def recommend_format(photo:, config:)
        return :carousel if config.format_prefer_carousels && carousel_candidate?(photo)
        return :reel if config.format_prefer_reels && reel_candidate?(photo)
        :static
      end

      def generate_hashtags(photo:, cluster:, config:)
        tags = []
        
        tags << cluster_hashtags(cluster) if cluster
        tags << photo_hashtags(photo)
        tags << generic_instagram_tags
        
        tags.flatten.compact.uniq.take(rand(config.hashtag_count_min..config.hashtag_count_max))
      end

      private

      def carousel_candidate?(photo)
        photo.respond_to?(:analysis) && 
          photo.analysis&.detected_objects&.any?
      end

      def reel_candidate?(photo)
        photo.respond_to?(:video?) && photo.video?
      end

      def cluster_hashtags(cluster)
        return [] unless cluster
        
        name_parts = cluster.name.downcase.split(/[\s_-]+/)
        name_parts.map { |part| "##{part}" }
      end

      def photo_hashtags(photo)
        return [] unless photo.respond_to?(:analysis)
        
        analysis = photo.analysis
        return [] unless analysis

        tags = []
        tags << analysis.detected_objects&.map { |obj| "##{obj.gsub(' ', '')}" } if analysis.respond_to?(:detected_objects)
        tags.flatten.compact
      end

      def generic_instagram_tags
        %w[#photography #instagood #photooftheday]
      end
    end
  end
end
