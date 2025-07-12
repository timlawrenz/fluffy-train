# frozen_string_literal: true

class Persona < ApplicationRecord
  has_many :photos, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
