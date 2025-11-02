module ContentStrategy
  class StrategyRegistry
    class << self
      def register(name, strategy_class)
        strategies[name.to_sym] = strategy_class
      end

      def get(name)
        strategies[name.to_sym] or raise UnknownStrategyError.new(name, all)
      end

      def all
        strategies.keys
      end

      def exists?(name)
        strategies.key?(name.to_sym)
      end

      private

      def strategies
        @strategies ||= {}
      end
    end
  end
end
