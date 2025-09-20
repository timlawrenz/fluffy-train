# frozen_string_literal: true

class Photo < ApplicationRecord
  # Only use neighbors in PostgreSQL environments (not SQLite for testing)
  has_neighbors :embedding unless Rails.env.test? && ActiveRecord::Base.connection.adapter_name == 'SQLite'
  has_one_attached :image

  belongs_to :persona

  validates :path, presence: true, uniqueness: true
end
