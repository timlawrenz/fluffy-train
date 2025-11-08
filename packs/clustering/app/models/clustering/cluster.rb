# frozen_string_literal: true

module Clustering
  class Cluster < ApplicationRecord
    self.table_name = 'clusters'

    belongs_to :persona
    has_many :photos, class_name: 'Photo', dependent: :nullify
    has_many :pillar_cluster_assignments, foreign_key: :cluster_id, dependent: :destroy
    has_many :pillars, through: :pillar_cluster_assignments, source: :pillar, class_name: 'ContentPillar'

    validates :persona, presence: true

    scope :for_persona, ->(persona_id) { where(persona_id: persona_id) }
    scope :for_pillar, ->(pillar) { joins(:pillar_cluster_assignments).where(pillar_cluster_assignments: { pillar_id: pillar.id }) }
    scope :available_for_posting, -> { where.not(id: nil) }
    scope :with_unposted_photos, -> {
      joins(:photos)
        .where.not(photos: { id: Scheduling::Post.where.not(photo_id: nil).select(:photo_id) })
        .distinct
    }

    def unposted_photos
      photos.where.not(id: Scheduling::Post.where.not(photo_id: nil).select(:photo_id))
    end

    def last_posted_at
      Scheduling::Post.where(cluster_id: id).order(created_at: :desc).first&.created_at
    end

    def unposted_photos_count
      unposted_photos.count
    end

    def primary_pillar
      pillar_cluster_assignments.find_by(primary: true)&.pillar
    end

    def pillar_names
      pillars.pluck(:name)
    end
  end
end
