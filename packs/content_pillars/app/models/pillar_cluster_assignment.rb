# frozen_string_literal: true

class PillarClusterAssignment < ApplicationRecord
  belongs_to :pillar, class_name: 'ContentPillar'
  belongs_to :cluster, class_name: 'Clustering::Cluster'

  validates :pillar, :cluster, presence: true
  validates :cluster_id, uniqueness: { scope: :pillar_id, message: 'already assigned to this pillar' }
  validate :same_persona

  private

  def same_persona
    return unless pillar && cluster

    return if pillar.persona_id == cluster.persona_id

    errors.add(:base, 'Pillar and cluster must belong to the same persona')
  end
end
