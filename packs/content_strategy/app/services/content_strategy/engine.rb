module ContentStrategy
  class Engine
    class << self
      def setup!
        register_strategies
        load_configuration
      end

      private

      def register_strategies
        StrategyRegistry.register(:theme_of_week_strategy, ThemeOfWeekStrategy)
        StrategyRegistry.register(:thematic_rotation_strategy, ThematicRotationStrategy)
      end

      def load_configuration
        ConfigLoader.load
      end
    end
  end
end
