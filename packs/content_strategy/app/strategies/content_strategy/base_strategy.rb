module ContentStrategy
  class BaseStrategy
    include Concerns::TimingOptimization
    include Concerns::VarietyEnforcement
    include Concerns::FormatOptimization

    attr_reader :context

    def initialize(context:)
      @context = context
    end

    def select_next_photo
      raise NotImplementedError, "Subclasses must implement select_next_photo"
    end

    def get_optimal_posting_time(photo:)
      calculate_optimal_posting_time(context: context)
    end

    def select_hashtags(photo:, cluster:)
      generate_hashtags(photo: photo, cluster: cluster, config: context.config)
    end

    def validate_posting_frequency
      posts_count = context.posts_this_week
      max_posts = context.config.posting_frequency_max
      
      if posts_count >= max_posts
        { allowed: false, reason: "Max weekly posts reached (#{posts_count}/#{max_posts})" }
      else
        { allowed: true }
      end
    end

    def before_post(photo:, cluster:)
    end

    def after_post(post:, photo:, cluster:)
      record_history(post: post, photo: photo, cluster: cluster)
      StateCache.invalidate(context.persona.id)
    end

    def name
      self.class.name.demodulize.underscore
    end

    protected

    def record_history(post:, photo:, cluster:)
      HistoryRecord.create!(
        persona: context.persona,
        post: post,
        cluster: cluster,
        strategy_name: name,
        decision_context: build_decision_context(photo: photo, cluster: cluster)
      )
    end

    def build_decision_context(photo:, cluster:)
      {
        photo_id: photo.id,
        cluster_id: cluster&.id,
        cluster_name: cluster&.name,
        strategy: name,
        timestamp: context.current_time.iso8601
      }
    end
  end
end
