# frozen_string_literal: true

class Photo < ApplicationRecord
  has_neighbors :embedding
  has_one_attached :image
  has_one :photo_analysis, dependent: :destroy

  belongs_to :persona

  validates :path, presence: true, uniqueness: true
end
