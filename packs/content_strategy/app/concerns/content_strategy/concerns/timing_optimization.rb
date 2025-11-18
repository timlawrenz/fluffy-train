module ContentStrategy
  module Concerns
    module TimingOptimization
      extend ActiveSupport::Concern

      def calculate_optimal_posting_time(context:, preferred_time: nil)
        config = context.config
        base_time = preferred_time || find_next_available_slot(context)

        time_in_zone = base_time.in_time_zone(config.timezone)
        current_hour = time_in_zone.hour

        if in_optimal_window?(current_hour, config)
          time_in_zone
        elsif in_alternative_window?(current_hour, config)
          time_in_zone
        else
          next_optimal_time(time_in_zone, config)
        end
      end

      private

      def find_next_available_slot(context)
        # Get the last scheduled post time
        last_scheduled = Scheduling::Post
          .where(persona: context.persona)
          .where(status: ['scheduled', 'draft'])
          .where.not(scheduled_at: nil)
          .maximum(:scheduled_at)

        # If no posts scheduled, use current time
        return context.current_time unless last_scheduled

        # Calculate days between posts based on weekly frequency
        config = context.config
        target_posts_per_week = (config.posting_frequency_min + config.posting_frequency_max) / 2.0
        days_between_posts = 7.0 / target_posts_per_week

        # Schedule next post after the appropriate interval
        last_scheduled + days_between_posts.days
      end

      def in_optimal_window?(hour, config)
        hour >= config.optimal_time_start_hour && hour < config.optimal_time_end_hour
      end

      def in_alternative_window?(hour, config)
        hour >= config.alternative_time_start_hour && hour < config.alternative_time_end_hour
      end

      def next_optimal_time(time, config)
        next_day = time.tomorrow
        next_day.change(hour: config.optimal_time_start_hour, min: rand(0..59))
      end
    end
  end
end
