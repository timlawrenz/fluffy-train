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
        persona = context.persona
        
        # Use intelligent generation if persona has hashtag strategy
        if persona.hashtag_strategy.present?
          result = HashtagGenerations::Generator.generate(
            photo: photo,
            persona: persona,
            cluster: cluster,
            count: count
          )
          result[:hashtags]
        else
          # Fallback to basic HashtagEngine
          HashtagEngine.generate(photo: photo, cluster: cluster, count: count)
        end
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
