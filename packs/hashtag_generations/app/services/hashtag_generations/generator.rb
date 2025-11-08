# frozen_string_literal: true

module HashtagGenerations
  # Main service for generating intelligent, persona-aware hashtags
  class Generator
    def self.generate(photo:, persona:, cluster: nil, count: 10)
      new(photo: photo, persona: persona, cluster: cluster, count: count).generate
    end

    def initialize(photo:, persona:, cluster: nil, count: 10)
      @photo = photo
      @persona = persona
      @cluster = cluster
      @count = count
    end

    def generate
      # If no hashtag strategy, fall back to basic generation
      return fallback_generation unless @persona.hashtag_strategy.present?
      
      # Step 1: Extract content-based tags
      content_tags = ContentAnalyzer.extract_tags(@photo)
      
      # Step 2: Add cluster-based tags
      cluster_tags = extract_cluster_tags
      
      # Step 3: Combine all candidate tags
      all_tags = (content_tags + cluster_tags).uniq
      
      # Step 4: Filter by persona alignment
      aligned_tags = PersonaAligner.filter_tags(all_tags, @persona)
      
      # Step 5: Score and rank tags
      scored_tags = RelevanceScorer.score_and_rank(aligned_tags)
      
      # Step 6: Optimize mix by size distribution
      optimized_tags = MixOptimizer.optimize(
        scored_tags,
        strategy: @persona.hashtag_strategy,
        target_count: @count
      )
      
      {
        hashtags: optimized_tags,
        metadata: build_metadata(content_tags, scored_tags, optimized_tags)
      }
    end

    private

    def fallback_generation
      # Use existing HashtagEngine
      tags = ContentStrategy::HashtagEngine.generate(
        photo: @photo,
        cluster: @cluster,
        count: @count
      )
      
      {
        hashtags: tags,
        metadata: {
          method: 'fallback',
          generated_by: 'HashtagEngine',
          generated_at: Time.current
        }
      }
    end

    def extract_cluster_tags
      return [] unless @cluster
      
      words = @cluster.name.downcase.split(/[\s_-]+/)
      words.select { |w| w.length > 2 }.map { |w| "##{w}" }
    end

    def build_metadata(content_tags, scored_tags, final_tags)
      {
        method: 'intelligent',
        generated_by: 'HashtagGenerations::Generator',
        generated_at: Time.current,
        content_tags_count: content_tags.size,
        total_candidates: scored_tags.size,
        selected_count: final_tags.size,
        has_persona_strategy: @persona.hashtag_strategy.present?
      }
    end
  end
end
