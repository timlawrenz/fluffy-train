module ContentStrategy
  class UnknownStrategyError < Error
    def initialize(strategy_name, available_strategies = [])
      super("Unknown strategy: #{strategy_name}. Available: #{available_strategies.join(', ')}")
    end
  end
end
