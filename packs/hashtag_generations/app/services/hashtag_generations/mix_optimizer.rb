# frozen_string_literal: true

module HashtagGenerations
  # Optimizes hashtag mix by size distribution for maximum reach
  class MixOptimizer
    def self.optimize(scored_tags, strategy: nil, target_count: 10)
      new(scored_tags, strategy: strategy, target_count: target_count).optimize
    end

    def initialize(scored_tags, strategy: nil, target_count: 10)
      @scored_tags = scored_tags
      @strategy = strategy
      @target_count = target_count
    end

    def optimize
      distribution = size_distribution
      
      selected = []
      
      # Select from each category based on distribution
      [:large, :medium, :niche].each do |category|
        range = distribution[category]
        count = range ? range.min : 0
        
        category_tags = @scored_tags.select { |t| t[:category] == category }
        selected.concat(category_tags.take(count))
      end
      
      # Fill remaining slots with highest scored tags not yet selected
      remaining = @target_count - selected.size
      if remaining > 0
        available = @scored_tags - selected
        selected.concat(available.take(remaining))
      end
      
      # Return just the tag strings
      selected.map { |t| t[:tag] }
    end

    private

    def size_distribution
      if @strategy
        @strategy.size_distribution
      else
        # Default balanced distribution
        { large: 2..3, medium: 3..4, niche: 3..5 }
      end
    end
  end
end
