module ContentStrategy
  class ThematicRotationStrategy < BaseStrategy
    def select_next_photo
      frequency_check = validate_posting_frequency
      return { error: frequency_check[:reason] } unless frequency_check[:allowed]

      cluster = select_next_cluster
      return { error: "No clusters available for rotation" } unless cluster

      photo = select_photo_from_cluster(cluster)
      return { error: "No photos available in cluster #{cluster.name}" } unless photo

      {
        photo: photo,
        cluster: cluster,
        optimal_time: get_optimal_posting_time(photo: photo),
        hashtags: select_hashtags(photo: photo, cluster: cluster),
        format: recommend_format(photo: photo, config: context.config)
      }
    end

    def after_post(post:, photo:, cluster:)
      super
      advance_rotation_index(cluster)
    end

    private

    def select_next_cluster
      available = context.available_clusters.to_a
      return nil if available.empty?

      variety_filtered = filter_by_variety(clusters: available, context: context)
      cluster_pool = variety_filtered.any? ? variety_filtered : available
      
      rotation_index = get_rotation_index
      cluster_pool[rotation_index % cluster_pool.size]
    end

    def get_rotation_index
      context.state.get_state(:rotation_index) || 0
    end

    def advance_rotation_index(cluster)
      current_index = get_rotation_index
      context.state.set_state(:rotation_index, current_index + 1)
    end

    def select_photo_from_cluster(cluster)
      Photo
        .where(cluster: cluster)
        .where.not(id: posted_photo_ids)
        .order("RANDOM()")
        .first
    end

    def posted_photo_ids
      Scheduling::Post
        .where(persona: context.persona)
        .where.not(photo_id: nil)
        .pluck(:photo_id)
    end
  end
end
