module ContentStrategy
  class HistoryRecord < ApplicationRecord
    self.table_name = "content_strategy_histories"

    belongs_to :persona
    belongs_to :post, class_name: "Scheduling::Post"
    belongs_to :cluster, optional: true
    belongs_to :pillar, class_name: "ContentPillar", optional: true

    validates :persona_id, presence: true
    validates :post_id, presence: true

    scope :recent, -> { order(created_at: :desc) }
    scope :for_persona, ->(persona_id) { where(persona_id: persona_id) }
    scope :for_cluster, ->(cluster_id) { where(cluster_id: cluster_id) }
    scope :for_pillar, ->(pillar_id) { where(pillar_id: pillar_id) }
    scope :recent_days, ->(days = 7) { where("created_at >= ?", days.days.ago) }
  end
end
