# frozen_string_literal: true

FactoryBot.define do
  factory :photo do
    persona
    sequence(:path) { |n| "/path/to/photo_#{n}.jpg" }
  end
end
