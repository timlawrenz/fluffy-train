module ContentStrategy
  module Concerns
    module VarietyEnforcement
      extend ActiveSupport::Concern

      def respects_variety_rules?(cluster:, context:)
        return true if cluster.nil?

        config = context.config
        recent_history = context.posting_history.limit(10)

        !recently_used?(cluster, recent_history, config) &&
          !overused_this_week?(cluster, context, config)
      end

      def filter_by_variety(clusters:, context:)
        config = context.config
        recent_history = context.posting_history.limit(10)
        
        clusters.reject do |cluster|
          recently_used?(cluster, recent_history, config) ||
            overused_this_week?(cluster, context, config)
        end
      end

      private

      def recently_used?(cluster, recent_history, config)
        min_gap = config.variety_min_days_gap.days.ago
        recent_history.where("created_at >= ?", min_gap).exists?(cluster_id: cluster.id)
      end

      def overused_this_week?(cluster, context, config)
        max_uses = config.variety_max_same_cluster
        week_start = context.current_time.beginning_of_week
        
        context.posting_history
          .where("created_at >= ?", week_start)
          .where(cluster_id: cluster.id)
          .count >= max_uses
      end
    end
  end
end
