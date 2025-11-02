module ContentStrategy
  class NoUnpostedPhotosError < Error
    def initialize(cluster_name)
      super("No unposted photos available in cluster '#{cluster_name}'")
    end
  end
end
