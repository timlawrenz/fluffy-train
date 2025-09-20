# frozen_string_literal: true

module Scheduling
  class Post < ApplicationRecord
    self.table_name = 'scheduling_posts'

    belongs_to :photo, class_name: 'Photo'
    belongs_to :persona, class_name: 'Persona'

    state_machine :status, initial: :draft do
      state :draft
      state :scheduled  
      state :posted
      state :failed

      event :schedule do
        transition draft: :scheduled
      end

      event :mark_as_posted do
        transition scheduled: :posted
      end

      event :mark_as_failed do
        transition scheduled: :failed
      end
    end
  end
end