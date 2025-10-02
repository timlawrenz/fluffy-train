# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

RSpec.describe Scheduling::SchedulePost, type: :command do
  let(:photo) { FactoryBot.build_stubbed(:photo) }
  let(:persona) { FactoryBot.build_stubbed(:persona) }
  let(:caption) { 'Test caption for scheduled post' }
  # The double for the created post must respond to `destroy!` for the rollback test.
  let(:created_post) { instance_double(Scheduling::Post, id: 1, destroy!: true) }

  # Mock command contexts that are more realistic for a chainable command.
  # They need to respond to `returns` and `errors` so the chainable can pass context.
  let(:create_post_context) { double('CreatePostContext', post: created_post, returns: { post: created_post }, errors: []) }
  let(:generate_url_context) { double('GenerateUrlContext', public_photo_url: 'https://example.com/photo.jpg', returns: { public_photo_url: 'https://example.com/photo.jpg' }, errors: []) }
  let(:send_to_instagram_context) { double('SendToInstagramContext', provider_post_id: '12345', returns: { provider_post_id: '12345' }, errors: []) }
  let(:update_post_context) { double('UpdatePostContext', post: created_post, returns: { post: created_post }, errors: []) }

  before do
    # Mock the individual commands
    RSpec::Mocks.allow_message(Scheduling::Commands::CreatePostRecord, :call).and_return(create_post_context)
    RSpec::Mocks.allow_message(Scheduling::Commands::GeneratePublicPhotoUrl, :call).and_return(generate_url_context)
    RSpec::Mocks.allow_message(Scheduling::Commands::SendPostToInstagram, :call).and_return(send_to_instagram_context)
    RSpec::Mocks.allow_message(Scheduling::Commands::UpdatePostWithInstagramId, :call).and_return(update_post_context)

    # Mock success status
    RSpec::Mocks.allow_message(create_post_context, :success?).and_return(true)
    RSpec::Mocks.allow_message(generate_url_context, :success?).and_return(true)
    RSpec::Mocks.allow_message(send_to_instagram_context, :success?).and_return(true)
    RSpec::Mocks.allow_message(update_post_context, :success?).and_return(true)
  end

  describe 'interface' do
    it { is_expected.to require(:photo).being(Photo) }
    it { is_expected.to require(:persona).being(Persona) }
    it { is_expected.to require(:caption).being(String) }
    it { is_expected.to returns(:post) }
  end

  describe 'command chain' do
    it 'defines the correct commands in order' do
      expect(described_class.commands).to eq([
                                               Scheduling::Commands::CreatePostRecord,
                                               Scheduling::Commands::GeneratePublicPhotoUrl,
                                               Scheduling::Commands::SendPostToInstagram,
                                               Scheduling::Commands::UpdatePostWithInstagramId
                                             ])
    end
  end

  describe '#call' do
    context 'with valid arguments' do
      it 'is successful when all commands succeed' do
        result = described_class.call(
          photo: photo,
          persona: persona,
          caption: caption
        )
        expect(result).to be_success
      end

      it 'returns the final post in context' do
        result = described_class.call(
          photo: photo,
          persona: persona,
          caption: caption
        )
        expect(result.post).to eq(created_post)
      end
    end

    context 'when a command in the chain fails' do
      before do
        # Make the second command fail
        RSpec::Mocks.allow_message(generate_url_context, :success?).and_return(false)
        RSpec::Mocks.allow_message(generate_url_context, :full_error_message).and_return('Photo URL generation failed')
      end

      it 'is a failure' do
        result = described_class.call(
          photo: photo,
          persona: persona,
          caption: caption
        )
        expect(result).to be_failure
      end

      it 'triggers rollback of previously executed commands' do
        # Expect the `destroy!` method to be called on the post that was "created" in the first step.
        expect(created_post).to receive(:destroy!)
        described_class.call(
          photo: photo,
          persona: persona,
          caption: caption
        )
      end
    end
  end
end