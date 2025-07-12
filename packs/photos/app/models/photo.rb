# frozen_string_literal: true

class Photo < ApplicationRecord
  belongs_to :persona

  validates :path, presence: true, uniqueness: true
end
