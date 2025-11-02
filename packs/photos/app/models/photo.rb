# frozen_string_literal: true

class Photo < ApplicationRecord
  has_neighbors :embedding
  has_one_attached :image
  has_one :photo_analysis, dependent: :destroy

  belongs_to :persona
  belongs_to :cluster, class_name: 'Clustering::Cluster', optional: true, counter_cache: true

  validates :path, presence: true, uniqueness: true

  scope :unposted, -> {
    where.not(id: Scheduling::Post.where.not(photo_id: nil).select(:photo_id))
  }
  scope :in_cluster, ->(cluster_id) { where(cluster_id: cluster_id) }

  def posted?
    Scheduling::Post.exists?(photo_id: id)
  end
end
