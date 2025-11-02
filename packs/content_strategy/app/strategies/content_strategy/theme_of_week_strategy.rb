module ContentStrategy
  class ThemeOfWeekStrategy < BaseStrategy
    def select_next_photo
      frequency_check = validate_posting_frequency
      return { error: frequency_check[:reason] } unless frequency_check[:allowed]

      cluster = get_or_set_weekly_cluster
      return { error: "No cluster available for theme of week" } unless cluster

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

    private

    def get_or_set_weekly_cluster
      state = context.state
      week_number = context.current_time.strftime("%Y-W%W")
      
      state_week = state.get_state(:week_number)
      state_cluster_id = state.get_state(:cluster_id)

      if state_week == week_number && state_cluster_id
        Cluster.find_by(id: state_cluster_id)
      else
        new_cluster = select_new_cluster
        if new_cluster
          state.set_state(:week_number, week_number)
          state.set_state(:cluster_id, new_cluster.id)
          state.update!(started_at: context.current_time)
        end
        new_cluster
      end
    end

    def select_new_cluster
      available = context.available_clusters.to_a
      return nil if available.empty?

      variety_filtered = filter_by_variety(clusters: available, context: context)
      
      cluster_pool = variety_filtered.any? ? variety_filtered : available
      cluster_pool.sample
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
