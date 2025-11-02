module ContentStrategy
  class Context
    attr_reader :persona, :current_time, :config

    def initialize(persona:, current_time: Time.current, config: nil)
      @persona = persona
      @current_time = current_time
      @config = config || ConfigLoader.load
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
      @available_clusters ||= Cluster.where(persona: persona).order(:name)
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
  end
end
