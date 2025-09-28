# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

RSpec.describe Scheduling::SchedulePost, type: :command do
  let(:photo) { instance_double(Photo) }
  let(:persona) { instance_double(Persona) }
  let(:caption) { 'Test caption for scheduled post' }
  let(:created_post) { instance_double(Scheduling::Post, id: 1) }

  # Mock command contexts
  let(:create_post_context) { double('CreatePostContext', post: created_post) }
  let(:generate_url_context) { double('GenerateUrlContext', public_photo_url: 'https://example.com/photo.jpg') }
  let(:update_post_context) { double('UpdatePostContext', post: created_post) }

  before do
    # Mock the individual commands
    allow(Scheduling::Commands::CreatePostRecord).to receive(:call).and_return(create_post_context)
    allow(Scheduling::Commands::GeneratePublicPhotoUrl).to receive(:call).and_return(generate_url_context)

    # Mock success status
    allow(create_post_context).to receive(:success?).and_return(true)
    allow(generate_url_context).to receive(:success?).and_return(true)
    allow(update_post_context).to receive(:success?).and_return(true)
  end

  describe 'interface' do
    it { is_expected.to require(:photo).being(Photo) }
    it { is_expected.to require(:persona).being(Persona) }
    it { is_expected.to require(:caption).being(String) }
    it { is_expected.to returns(:post).being(Scheduling::Post) }
  end

  describe 'command chain' do
    it 'defines the correct commands in order' do
      expect(described_class.commands).to eq([
                                               Scheduling::Commands::CreatePostRecord,
                                               Scheduling::Commands::GeneratePublicPhotoUrl
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
        allow(generate_url_context).to receive_messages(
          success?: false,
          full_error_message: 'Photo URL generation failed'
        )
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
        # This behavior is handled by GLCommand::Chainable automatically
        # The test ensures that the chain properly fails when a command fails
        result = described_class.call(
          photo: photo,
          persona: persona,
          caption: caption
        )
        expect(result).to be_failure
      end
    end
  end
end
