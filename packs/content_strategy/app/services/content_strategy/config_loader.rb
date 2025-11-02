module ContentStrategy
  class ConfigLoader
    class << self
      def load
        @config ||= begin
          yaml_config = YAML.load_file(config_path)[Rails.env] || {}
          StrategyConfig.from_yaml(yaml_config)
        end
      end

      def reload!
        @config = nil
        load
      end

      private

      def config_path
        Rails.root.join("config", "content_strategy.yml")
      end
    end
  end
end
