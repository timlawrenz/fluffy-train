module ContentStrategy
  class StrategyConfig
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :posting_frequency_min, :integer, default: 3
    attribute :posting_frequency_max, :integer, default: 5
    attribute :posting_days_gap, :integer, default: 1

    attribute :optimal_time_start_hour, :integer, default: 5
    attribute :optimal_time_end_hour, :integer, default: 8
    attribute :alternative_time_start_hour, :integer, default: 10
    attribute :alternative_time_end_hour, :integer, default: 15
    attribute :timezone, :string, default: "UTC"

    attribute :variety_min_days_gap, :integer, default: 2
    attribute :variety_max_same_cluster, :integer, default: 3

    attribute :hashtag_count_min, :integer, default: 5
    attribute :hashtag_count_max, :integer, default: 12

    attribute :format_prefer_reels, :boolean, default: false
    attribute :format_prefer_carousels, :boolean, default: true

    validates :posting_frequency_min, numericality: { greater_than: 0, less_than_or_equal_to: 7 }
    validates :posting_frequency_max, numericality: { greater_than: 0, less_than_or_equal_to: 7 }
    validates :optimal_time_start_hour, numericality: { greater_than_or_equal_to: 0, less_than: 24 }
    validates :optimal_time_end_hour, numericality: { greater_than_or_equal_to: 0, less_than: 24 }
    validates :variety_min_days_gap, numericality: { greater_than_or_equal_to: 0 }
    validates :hashtag_count_min, numericality: { greater_than_or_equal_to: 0 }
    validates :hashtag_count_max, numericality: { greater_than_or_equal_to: 0 }

    def self.from_yaml(yaml_hash)
      new(yaml_hash.symbolize_keys)
    end

    def self.default
      new
    end
  end
end
