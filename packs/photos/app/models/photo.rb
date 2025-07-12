# frozen_string_literal: true

class Photo < ApplicationRecord
  has_vector :embedding, dimensions: 512

  belongs_to :persona

  validates :path, presence: true, uniqueness: true
end
