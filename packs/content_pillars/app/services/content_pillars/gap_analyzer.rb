# frozen_string_literal: true

module ContentPillars
  class GapAnalyzer
    def initialize(persona:)
      @persona = persona
    end

    def analyze(days_ahead: 30)
      pillars = @persona.content_pillars.current.by_priority
      
      return [] if pillars.empty?

      total_posts_needed = calculate_total_posts_needed(days_ahead)
      
      pillars.map do |pillar|
        analyze_pillar(pillar, total_posts_needed)
      end.sort_by { |result| [-result[:gap], -result[:pillar].priority] }
    end

    private

    def analyze_pillar(pillar, total_posts_needed)
      posts_needed = calculate_pillar_posts_needed(pillar, total_posts_needed)
      photos_available = count_available_photos(pillar)
      gap = posts_needed - photos_available
      
      {
        pillar: pillar,
        posts_needed: posts_needed,
        photos_available: photos_available,
        gap: gap,
        status: determine_status(gap, photos_available),
        priority: determine_priority(gap, photos_available, pillar)
      }
    end

    def calculate_total_posts_needed(days_ahead)
      # Default posting frequency: ~3 posts/week = 0.43 posts/day
      posts_per_week = 3
      weeks = days_ahead.to_f / 7.0
      (posts_per_week * weeks).ceil
    end

    def calculate_pillar_posts_needed(pillar, total_posts_needed)
      # If pillar has target_posts_per_week, use that
      if pillar.target_posts_per_week.present?
        weeks = 30.0 / 7.0 # Default lookahead
        return (pillar.target_posts_per_week * weeks).ceil
      end
      
      # Otherwise use weight percentage
      (total_posts_needed * pillar.weight / 100.0).ceil
    end

    def count_available_photos(pillar)
      posted_photo_ids = Scheduling::Post
        .where(persona: @persona)
        .where.not(photo_id: nil)
        .pluck(:photo_id)
      
      pillar.clusters
        .joins(:photos)
        .where(photos: { persona_id: @persona.id })
        .where.not(photos: { id: posted_photo_ids })
        .distinct
        .count('photos.id')
    end

    def determine_status(gap, photos_available)
      return :exhausted if photos_available == 0
      return :critical if gap > 5
      return :low if gap > 0
      return :ready if gap <= 0 && photos_available >= 3
      :minimal
    end

    def determine_priority(gap, photos_available, pillar)
      return :high if gap > 5 || photos_available == 0
      return :medium if gap > 0
      return :low if gap <= 0 && photos_available >= 5
      :normal
    end
  end
end
