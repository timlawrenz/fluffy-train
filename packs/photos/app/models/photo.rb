# frozen_string_literal: true

class Photo < ApplicationRecord
  has_neighbors :embedding

  belongs_to :persona

  validates :path, presence: true, uniqueness: true
end
