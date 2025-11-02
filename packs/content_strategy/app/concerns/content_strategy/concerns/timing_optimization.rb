module ContentStrategy
  module Concerns
    module TimingOptimization
      extend ActiveSupport::Concern

      def calculate_optimal_posting_time(context:, preferred_time: nil)
        config = context.config
        base_time = preferred_time || context.current_time

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
