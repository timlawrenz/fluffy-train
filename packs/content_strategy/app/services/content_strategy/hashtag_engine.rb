module ContentStrategy
  class HashtagEngine
    POPULAR_HASHTAGS = %w[
      photography photooftheday instagood picoftheday instadaily
      beautiful art nature travel love
    ].freeze

    NICHE_HASHTAGS = {
      landscape: %w[landscapephotography naturephotography outdoors mountains sunset],
      portrait: %w[portraitphotography portraiture people face beauty],
      urban: %w[streetphotography cityscape architecture urbanphotography city],
      nature: %w[naturephotography wildlife outdoors hiking explore],
      food: %w[foodphotography foodie instafood yummy delicious]
    }.freeze

    def self.generate(photo:, cluster:, count: 8)
      new(photo: photo, cluster: cluster, count: count).generate
    end

    attr_reader :photo, :cluster, :count

    def initialize(photo:, cluster:, count: 8)
      @photo = photo
      @cluster = cluster
      @count = count
    end

    def generate
      tags = []
      
      tags.concat(cluster_based_tags)
      tags.concat(popular_tags)
      tags.concat(niche_tags)
      tags.concat(photo_analysis_tags) if photo.photo_analysis
      
      tags.uniq.take(count).map { |tag| format_hashtag(tag) }
    end

    private

    def cluster_based_tags
      return [] unless cluster
      
      cluster.name.downcase.split(/[\s_-]+/).select { |word| word.length > 2 }
    end

    def popular_tags
      POPULAR_HASHTAGS.sample(2)
    end

    def niche_tags
      category = detect_category
      NICHE_HASHTAGS[category]&.sample(3) || []
    end

    def photo_analysis_tags
      analysis = photo.photo_analysis
      tags = []
      
      if analysis.respond_to?(:tags) && analysis.tags.present?
        tags.concat(analysis.tags.first(3))
      end
      
      tags
    end

    def detect_category
      return :landscape if cluster&.name&.match?(/landscape|nature|mountain|outdoor/i)
      return :portrait if cluster&.name&.match?(/portrait|people|face/i)
      return :urban if cluster&.name&.match?(/city|urban|street|architecture/i)
      return :food if cluster&.name&.match?(/food|meal|restaurant/i)
      
      :nature
    end

    def format_hashtag(tag)
      tag = tag.to_s.downcase.gsub(/[^a-z0-9]/, '')
      tag.start_with?('#') ? tag : "##{tag}"
    end
  end
end
