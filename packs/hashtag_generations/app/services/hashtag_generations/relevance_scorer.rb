# frozen_string_literal: true

module HashtagGenerations
  # Scores hashtags by size category and relevance
  class RelevanceScorer
    # Estimated Instagram hashtag sizes (approximate post counts)
    # These should ideally be updated from real data, but serve as starting point
    HASHTAG_SIZES = {
      # Large (1M+ posts)
      large: %w[
        #photography #photooftheday #instagood #picoftheday #instadaily
        #beautiful #art #nature #travel #love #fashion #style #ootd
        #beauty #selfie #photo #happy #sunset #model #girl #summer
      ],
      
      # Medium (100K-500K posts)
      medium: %w[
        #landscapephotography #portraitphotography #streetphotography
        #naturephotography #cityphotography #urbanphotography
        #lifestylephotography #goldenhour #architecturelovers
        #sunsetlovers #cityvibes #urbanexplorer #coffeetime
        #morningvibes #eveningvibes #weekendvibes
      ],
      
      # Niche (10K-50K posts) - These are more specific and engaged
      niche: %w[
        #urbanarchitecture #cityarchitecture #modernarchitecture
        #architecturalphotography #urbansunset #citysunset
        #coffeeculture #coffeephotography #latteart
        #streetstyle #urbanstyle #minimaliststyle
        #portraitmood #moodyphotography #moodygrams
      ]
    }.freeze

    def self.score_and_rank(tags)
      new(tags).score_and_rank
    end

    def initialize(tags)
      @tags = tags.uniq
    end

    def score_and_rank
      scored_tags = @tags.map do |tag|
        {
          tag: tag,
          score: calculate_score(tag),
          category: categorize_size(tag)
        }
      end
      
      scored_tags.sort_by { |t| -t[:score] }
    end

    private

    def calculate_score(tag)
      score = 0.0
      
      # Size category scoring (medium is sweet spot)
      score += case categorize_size(tag)
               when :large then 3.0
               when :medium then 5.0  # Higher engagement rate
               when :niche then 4.0   # Very engaged audience
               else 2.0
               end
      
      # Bonus for specific/descriptive tags
      score += 2.0 if tag.length > 15  # More specific hashtags
      
      # Bonus for compound words (e.g., #UrbanSunset)
      score += 1.0 if tag.match?(/[a-z][A-Z]/)
      
      score
    end

    def categorize_size(tag)
      tag_lower = tag.downcase
      
      return :large if HASHTAG_SIZES[:large].any? { |h| h.downcase == tag_lower }
      return :medium if HASHTAG_SIZES[:medium].any? { |h| h.downcase == tag_lower }
      return :niche if HASHTAG_SIZES[:niche].any? { |h| h.downcase == tag_lower }
      
      # Default categorization based on specificity
      if tag.length > 20
        :niche
      elsif tag.length > 12
        :medium
      else
        :large
      end
    end
  end
end
