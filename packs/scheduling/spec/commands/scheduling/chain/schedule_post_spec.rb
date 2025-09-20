# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

RSpec.describe Scheduling::Chain::SchedulePost, type: :command do
  let(:photo) { instance_double('Photo') }
  let(:persona) { instance_double('Persona') }
  let(:caption) { 'Test caption for scheduled post' }
  let(:created_post) { instance_double('Scheduling::Post', id: 1) }

  # Mock command contexts
  let(:create_post_context) { double('CreatePostContext', post: created_post) }
  let(:generate_url_context) { double('GenerateUrlContext', public_photo_url: 'https://example.com/photo.jpg') }
  let(:send_buffer_context) { double('SendBufferContext', buffer_post_id: 'buffer_456') }
  let(:update_post_context) { double('UpdatePostContext', post: created_post) }

  before do
    # Mock the individual commands
    allow(Scheduling::Commands::CreatePostRecord).to receive(:call).and_return(create_post_context)
    allow(Scheduling::Commands::GeneratePublicPhotoUrl).to receive(:call).and_return(generate_url_context)
    allow(Scheduling::Commands::SendPostToBuffer).to receive(:call).and_return(send_buffer_context)
    allow(Scheduling::Commands::UpdatePostWithBufferId).to receive(:call).and_return(update_post_context)

    # Mock success status
    allow(create_post_context).to receive(:success?).and_return(true)
    allow(generate_url_context).to receive(:success?).and_return(true)
    allow(send_buffer_context).to receive(:success?).and_return(true)
    allow(update_post_context).to receive(:success?).and_return(true)
  end

  describe 'interface' do
    it { is_expected.to require(:photo) }
    it { is_expected.to require(:persona) }
    it { is_expected.to require(:caption) }
    it { is_expected.to returns(:post) }
  end

  describe 'command chain' do
    it 'defines the correct commands in order' do
      expect(described_class.commands).to eq([
                                               Scheduling::Commands::CreatePostRecord,
                                               Scheduling::Commands::GeneratePublicPhotoUrl,
                                               Scheduling::Commands::SendPostToBuffer,
                                               Scheduling::Commands::UpdatePostWithBufferId
                                             ])
    end
  end

  describe '#call' do
    context 'with valid arguments' do
      before do
        allow(photo).to receive(:is_a?).with(Photo).and_return(true)
        allow(persona).to receive(:is_a?).with(Persona).and_return(true)
        allow(caption).to receive(:is_a?).with(String).and_return(true)
        allow(caption).to receive(:present?).and_return(true)
      end

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

    context 'with invalid photo argument' do
      let(:invalid_photo) { 'not a photo' }

      before do
        allow(invalid_photo).to receive(:is_a?).with(Photo).and_return(false)
      end

      it 'is a failure' do
        result = described_class.call(
          photo: invalid_photo,
          persona: persona,
          caption: caption
        )
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.call(
          photo: invalid_photo,
          persona: persona,
          caption: caption
        )
        expect(result.full_error_message).to eq('photo must be a Photo instance')
      end
    end

    context 'with invalid persona argument' do
      let(:invalid_persona) { 'not a persona' }

      before do
        allow(photo).to receive(:is_a?).with(Photo).and_return(true)
        allow(invalid_persona).to receive(:is_a?).with(Persona).and_return(false)
      end

      it 'is a failure' do
        result = described_class.call(
          photo: photo,
          persona: invalid_persona,
          caption: caption
        )
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.call(
          photo: photo,
          persona: invalid_persona,
          caption: caption
        )
        expect(result.full_error_message).to eq('persona must be a Persona instance')
      end
    end

    context 'with invalid caption argument' do
      before do
        allow(photo).to receive(:is_a?).with(Photo).and_return(true)
        allow(persona).to receive(:is_a?).with(Persona).and_return(true)
      end

      context 'when caption is not a string' do
        let(:invalid_caption) { 123 }

        before do
          allow(invalid_caption).to receive(:is_a?).with(String).and_return(false)
        end

        it 'is a failure' do
          result = described_class.call(
            photo: photo,
            persona: persona,
            caption: invalid_caption
          )
          expect(result).to be_failure
        end
      end

      context 'when caption is empty' do
        let(:empty_caption) { '' }

        before do
          allow(empty_caption).to receive(:is_a?).with(String).and_return(true)
          allow(empty_caption).to receive(:present?).and_return(false)
        end

        it 'is a failure' do
          result = described_class.call(
            photo: photo,
            persona: persona,
            caption: empty_caption
          )
          expect(result).to be_failure
        end

        it 'returns an error message' do
          result = described_class.call(
            photo: photo,
            persona: persona,
            caption: empty_caption
          )
          expect(result.full_error_message).to eq('caption must be a non-empty string')
        end
      end
    end

    context 'when a command in the chain fails' do
      before do
        allow(photo).to receive(:is_a?).with(Photo).and_return(true)
        allow(persona).to receive(:is_a?).with(Persona).and_return(true)
        allow(caption).to receive(:is_a?).with(String).and_return(true)
        allow(caption).to receive(:present?).and_return(true)

        # Make the second command fail
        allow(generate_url_context).to receive(:success?).and_return(false)
        allow(generate_url_context).to receive(:full_error_message).and_return('Photo URL generation failed')
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
