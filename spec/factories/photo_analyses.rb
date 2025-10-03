# frozen_string_literal: true

FactoryBot.define do
  factory :photo_analysis do
    photo
    sharpness_score { rand(0.0..1.0) }
    exposure_score { rand(0.0..1.0) }
    aesthetic_score { rand(0.0..1.0) }
    detected_objects { [{ 'object' => 'person', 'confidence' => 0.95 }, { 'object' => 'car', 'confidence' => 0.80 }] }
    caption { 'A beautiful photo captured in perfect lighting.' }
  end
end
