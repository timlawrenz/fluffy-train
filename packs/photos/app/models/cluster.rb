# frozen_string_literal: true

class Cluster < ApplicationRecord
  has_many :photos, dependent: :nullify
end
