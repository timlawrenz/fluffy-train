# frozen_string_literal: true

FactoryBot.define do
  factory :scheduling_post, class: 'Scheduling::Post' do
    photo
    persona
    caption { 'Sample caption for the post' }
    status { 'draft' }
  end
end