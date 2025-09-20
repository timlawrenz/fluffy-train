# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scheduling::Post do
  describe 'associations' do
    it 'belongs to a photo' do
      expect(described_class.reflect_on_association(:photo)).to be_a(ActiveRecord::Reflection::BelongsToReflection)
    end

    it 'belongs to a persona' do
      expect(described_class.reflect_on_association(:persona)).to be_a(ActiveRecord::Reflection::BelongsToReflection)
    end
  end

  describe 'validations' do
    let(:post) { FactoryBot.build(:scheduling_post) }

    it 'is valid with valid attributes' do
      expect(post).to be_valid
    end

    it 'is not valid without a photo' do
      post.photo = nil
      expect(post).not_to be_valid
      expect(post.errors[:photo]).to include('must exist')
    end

    it 'is not valid without a persona' do
      post.persona = nil
      expect(post).not_to be_valid
      expect(post.errors[:persona]).to include('must exist')
    end
  end

  describe 'state machine' do
    let(:post) { FactoryBot.create(:scheduling_post) }

    it 'has draft as initial state' do
      expect(post.status).to eq('draft')
      expect(post).to be_draft
    end

    describe 'schedule event' do
      it 'transitions from draft to scheduled' do
        expect(post).to be_draft
        post.schedule
        expect(post).to be_scheduled
      end

      it 'cannot schedule from non-draft states' do
        post.schedule
        expect(post).to be_scheduled
        expect { post.schedule }.to raise_error(StateMachines::InvalidTransition)
      end
    end

    describe 'mark_as_posted event' do
      it 'transitions from scheduled to posted' do
        post.schedule
        expect(post).to be_scheduled
        post.mark_as_posted
        expect(post).to be_posted
      end

      it 'cannot mark as posted from non-scheduled states' do
        expect(post).to be_draft
        expect { post.mark_as_posted }.to raise_error(StateMachines::InvalidTransition)
      end
    end

    describe 'mark_as_failed event' do
      it 'transitions from scheduled to failed' do
        post.schedule
        expect(post).to be_scheduled
        post.mark_as_failed
        expect(post).to be_failed
      end

      it 'cannot mark as failed from non-scheduled states' do
        expect(post).to be_draft
        expect { post.mark_as_failed }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end
end
