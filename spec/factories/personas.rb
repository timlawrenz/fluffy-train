# frozen_string_literal: true

FactoryBot.define do
  factory :persona do
    sequence(:name) { |n| "Persona #{n}" }
  end
end
