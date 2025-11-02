# frozen_string_literal: true

module Clustering
  class Cluster < ApplicationRecord
    self.table_name = 'clusters'

    has_many :photos, class_name: 'Photo', dependent: :nullify
  end
end
