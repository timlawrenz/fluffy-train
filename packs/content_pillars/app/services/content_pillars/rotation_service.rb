# frozen_string_literal: true

module ContentPillars
  class RotationService
    def initialize(persona:)
      @persona = persona
    end

    # Select the next pillar to post from based on weighted rotation
    def select_next_pillar
      pillars = @persona.content_pillars.current.by_priority
      
      return nil if pillars.empty?
      
      # Calculate how "behind" each pillar is relative to its target weight
      scored_pillars = pillars.map do |pillar|
        {
          pillar: pillar,
          score: calculate_deficit_score(pillar)
        }
      end
      
      # Sort by score (highest = most behind target)
      # Then by priority as tiebreaker
      scored_pillars.sort_by do |sp|
        [-sp[:score], -sp[:pillar].priority]
      end.first&.dig(:pillar)
    end

    private

    def calculate_deficit_score(pillar)
      # Get total posts and pillar's posts
      total_posts = recent_post_count
      return pillar.weight if total_posts == 0 # No posts yet, use weight
      
      pillar_posts = pillar_post_count(pillar)
      
      # Calculate actual vs target percentage
      actual_percentage = (pillar_posts.to_f / total_posts * 100)
      target_percentage = pillar.weight
      
      # Deficit = how far below target (positive = behind, negative = ahead)
      deficit = target_percentage - actual_percentage
      
      # Boost score if pillar has available photos
      available_photos = count_available_photos(pillar)
      
      # Penalize if no photos available
      return -1000 if available_photos == 0
      
      # Return deficit score (higher = more behind target)
      deficit
    end

    def recent_post_count(days_back: 30)
      ContentStrategy::HistoryRecord
        .where(persona: @persona)
        .where('created_at >= ?', days_back.days.ago)
        .count
    end

    def pillar_post_count(pillar, days_back: 30)
      # Check history records first (if pillar tracking is implemented)
      # For now, approximate from cluster posts
      cluster_ids = pillar.clusters.pluck(:id)
      
      ContentStrategy::HistoryRecord
        .where(persona: @persona)
        .where(cluster_id: cluster_ids)
        .where('created_at >= ?', days_back.days.ago)
        .count
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
  end
end
