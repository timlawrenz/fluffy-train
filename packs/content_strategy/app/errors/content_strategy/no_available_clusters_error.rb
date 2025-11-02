module ContentStrategy
  class NoAvailableClustersError < Error
    def initialize(persona_id)
      super("No available clusters for persona #{persona_id}")
    end
  end
end
