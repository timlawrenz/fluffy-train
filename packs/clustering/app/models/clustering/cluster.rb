# frozen_string_literal: true

module Clustering
  class Cluster < ApplicationRecord
    self.table_name = 'clusters'

    has_many :photos, class_name: 'Photo', dependent: :nullify

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
  end
end
