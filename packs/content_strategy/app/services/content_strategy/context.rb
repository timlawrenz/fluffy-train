module ContentStrategy
  class Context
    attr_reader :persona, :current_time, :config, :selected_pillar

    def initialize(persona:, current_time: Time.current, config: nil, pillar: nil)
      @persona = persona
      @current_time = current_time
      @config = config || ConfigLoader.load
      @selected_pillar = pillar
    end

    def posting_history
      @posting_history ||= HistoryRecord
        .for_persona(persona.id)
        .recent_days(7)
        .order(created_at: :desc)
    end

    def state
      @state ||= StateCache.get(persona.id) || StrategyState.find_or_create_by!(persona: persona)
    end

    def available_clusters
      # If pillar is specified, only return clusters from that pillar
      base_scope = if selected_pillar
                     selected_pillar.clusters
                   else
                     persona.clusters
                   end

      @available_clusters ||= base_scope
        .joins(:photos)
        .where.not(photos: { id: Scheduling::Post.where.not(photo_id: nil).select(:photo_id) })
        .distinct
        .order(:name)
    end

    def recent_cluster_ids
      @recent_cluster_ids ||= posting_history.pluck(:cluster_id).compact.uniq
    end

    def posts_this_week
      @posts_this_week ||= posting_history.where("created_at >= ?", current_time.beginning_of_week).count
    end

    def state_config
      state.strategy_config.presence || {}
    end

    # Pillar-aware methods
    def use_pillar_rotation?
      persona.content_pillars.current.any?
    end

    def select_pillar
      return nil unless use_pillar_rotation?
      
      @selected_pillar ||= ContentPillars::RotationService.new(persona: persona).select_next_pillar
    end
  end
end
