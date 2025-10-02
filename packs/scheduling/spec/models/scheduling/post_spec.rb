# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scheduling::Post do
  describe 'associations' do
    it { is_expected.to belong_to(:photo).class_name('Photo') }
    it { is_expected.to belong_to(:persona).class_name('Persona') }
  end

  describe 'state machine' do
    let(:post) { FactoryBot.create(:scheduling_post) }

    it 'has an initial state of draft' do
      expect(post).to be_draft
    end

    describe 'schedule event' do
      it 'transitions from draft to scheduled' do
        post.schedule
        expect(post).to be_scheduled
      end

      it 'cannot schedule from non-draft states' do
        post.status = 'scheduled'
        expect { post.schedule! }.to raise_error(StateMachines::InvalidTransition)
      end
    end

    describe 'start_posting event' do
      it 'transitions from draft to posting' do
        post.start_posting
        expect(post).to be_posting
      end

      it 'cannot start posting from non-draft states' do
        post.status = 'scheduled'
        expect { post.start_posting! }.to raise_error(StateMachines::InvalidTransition)
      end
    end

    describe 'mark_as_posted event' do
      it 'transitions from scheduled to posted' do
        post.status = 'scheduled'
        post.mark_as_posted
        expect(post).to be_posted
      end

      it 'transitions from posting to posted' do
        post.status = 'posting'
        post.mark_as_posted
        expect(post).to be_posted
      end

      it 'cannot mark as posted from non-scheduled/posting states' do
        post.status = 'draft'
        expect { post.mark_as_posted! }.to raise_error(StateMachines::InvalidTransition)
      end
    end

    describe 'mark_as_failed event' do
      it 'transitions from scheduled to failed' do
        post.status = 'scheduled'
        post.mark_as_failed
        expect(post).to be_failed
      end

      it 'transitions from posting to failed' do
        post.status = 'posting'
        post.mark_as_failed
        expect(post).to be_failed
      end

      it 'cannot mark as failed from non-scheduled/posting states' do
        post.status = 'draft'
        expect { post.mark_as_failed! }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end
end
