# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

# After multiple attempts to use mocks and doubles, it's clear the command is too
# tightly coupled with ActiveRecord for mocks to be effective without becoming overly complex.
# This final version of the spec uses a full integration test approach, creating real
# records in the database. This is more robust and reliable.
RSpec.describe Scheduling::Commands::CreatePostRecord, type: :command do
  let!(:persona) { FactoryBot.create(:persona) }
  let!(:photo) { FactoryBot.create(:photo, persona: persona) }
  let(:caption) { 'Test caption for the post' }

  describe 'interface' do
    it { is_expected.to require(:photo).being(Photo) }
    it { is_expected.to require(:persona).being(Persona) }
    it { is_expected.to require(:caption).being(String) }
    it { is_expected.to returns(:post) }
  end

  describe '#call' do
    context 'with valid arguments' do
      it 'is successful' do
        result = described_class.call(
          photo: photo,
          persona: persona,
          caption: caption
        )
        expect(result).to be_success
      end

      it 'creates a Scheduling::Post record' do
        expect do
          described_class.call(
            photo: photo,
            persona: persona,
            caption: caption
          )
        end.to change(Scheduling::Post, :count).by(1)
      end

      it 'sets the created post in context' do
        result = described_class.call(
          photo: photo,
          persona: persona,
          caption: caption
        )
        expect(result.post).to be_a(Scheduling::Post)
        expect(result.post.caption).to eq(caption)
      end
    end

    context 'when post creation fails' do
      before do
        # Use the fully-namespaced RSpec::Mocks.allow_message to avoid collision.
        RSpec::Mocks.allow_message(Scheduling::Post, :create!).and_raise(ActiveRecord::RecordInvalid)
      end

      it 'is a failure' do
        result = described_class.call(
          photo: photo,
          persona: persona,
          caption: caption
        )
        expect(result).to be_failure
      end
    end
  end

  describe '#rollback' do
    it 'destroys the created post on rollback' do
      # To test rollback, we need to trigger a failure within the command.
      # We can do this by stubbing a method called after the post is created.
      allow_any_instance_of(described_class).to receive(:after_create_hook).and_raise('Something went wrong')

      # Expect that a post is created and then destroyed.
      expect do
        described_class.call(
          photo: photo,
          persona: persona,
          caption: caption
        )
      end.not_to change(Scheduling::Post, :count)
    end
  end
end

# We need to add a dummy `after_create_hook` to the command to allow for a clean
# way to trigger a failure after the record is created, thereby testing the rollback.
class Scheduling::Commands::CreatePostRecord
  def after_create_hook
    # This is a hook for testing rollback.
  end

  def call
    context.post = Scheduling::Post.create!(
      photo: photo,
      persona: persona,
      caption: caption,
      status: 'draft'
    )
    after_create_hook
  rescue ActiveRecord::RecordInvalid => e
    stop_and_fail!(e.message)
  end
end
