# frozen_string_literal: true

FactoryBot.define do
  factory :cluster do
    name { 'Sample Cluster' }
    status { 0 }
    photos_count { 0 }
  end
end
