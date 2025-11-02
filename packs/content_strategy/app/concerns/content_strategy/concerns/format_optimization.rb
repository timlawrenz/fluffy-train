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
        count = rand(config.hashtag_count_min..config.hashtag_count_max)
        HashtagEngine.generate(photo: photo, cluster: cluster, count: count)
      end

      private

      def carousel_candidate?(photo)
        photo.respond_to?(:analysis) && 
          photo.analysis&.detected_objects&.any?
      end

      def reel_candidate?(photo)
        photo.respond_to?(:video?) && photo.video?
      end
    end
  end
end
