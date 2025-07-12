# frozen_string_literal: true

class Persona < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
