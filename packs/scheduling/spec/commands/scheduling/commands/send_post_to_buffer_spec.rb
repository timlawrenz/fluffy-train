# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

RSpec.describe Scheduling::Commands::SendPostToBuffer, type: :command do
  let(:public_photo_url) { 'https://example.com/photo.jpg' }
  let(:caption) { 'Test caption for Buffer post' }
  let(:persona) { instance_double('Persona', buffer_profile_id: 'buffer_profile_123') }
  let(:buffer_client) { instance_double('Buffer::Client') }
  let(:buffer_response) { { 'id' => 'buffer_post_456' } }

  before do
    allow(Buffer::Client).to receive(:new).and_return(buffer_client)
    allow(buffer_client).to receive(:create_post).and_return(buffer_response)
    allow(buffer_client).to receive(:destroy_post)
    allow(Rails.logger).to receive(:error)
  end

  describe 'interface' do
    it { is_expected.to require(:public_photo_url).being(String) }
    it { is_expected.to require(:caption).being(String) }
    it { is_expected.to require(:persona).being(Persona) }
    it { is_expected.to returns(:buffer_post_id).being(String) }
  end

  describe '#call' do
    context 'with valid arguments and successful Buffer API call' do
      it 'is successful' do
        result = described_class.call(
          public_photo_url: public_photo_url,
          caption: caption,
          persona: persona
        )
        expect(result).to be_success
      end

      it 'calls Buffer API with correct parameters' do
        expect(buffer_client).to receive(:create_post).with(
          image_url: public_photo_url,
          caption: caption,
          buffer_profile_id: 'buffer_profile_123'
        )

        described_class.call(
          public_photo_url: public_photo_url,
          caption: caption,
          persona: persona
        )
      end

      it 'sets the buffer_post_id in context' do
        result = described_class.call(
          public_photo_url: public_photo_url,
          caption: caption,
          persona: persona
        )
        expect(result.buffer_post_id).to eq('buffer_post_456')
      end
    end

    context 'when persona has no buffer_profile_id' do
      let(:persona) { instance_double('Persona', buffer_profile_id: nil) }

      before do
        allow(persona).to receive(:respond_to?).with(:buffer_profile_id).and_return(true)
      end

      it 'is a failure' do
        result = described_class.call(
          public_photo_url: public_photo_url,
          caption: caption,
          persona: persona
        )
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.call(
          public_photo_url: public_photo_url,
          caption: caption,
          persona: persona
        )
        expect(result.full_error_message).to eq('Persona must have a buffer_profile_id')
      end
    end

    context 'when Buffer API returns no post ID' do
      let(:buffer_response) { { 'other_field' => 'value' } }

      it 'is a failure' do
        result = described_class.call(
          public_photo_url: public_photo_url,
          caption: caption,
          persona: persona
        )
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.call(
          public_photo_url: public_photo_url,
          caption: caption,
          persona: persona
        )
        expect(result.full_error_message).to eq('Buffer API did not return a post ID')
      end
    end

    context 'when Buffer API raises an error' do
      before do
        allow(buffer_client).to receive(:create_post).and_raise(Buffer::Client::Error, 'API error')
      end

      it 'is a failure' do
        result = described_class.call(
          public_photo_url: public_photo_url,
          caption: caption,
          persona: persona
        )
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.call(
          public_photo_url: public_photo_url,
          caption: caption,
          persona: persona
        )
        expect(result.full_error_message).to eq('Failed to send post to Buffer: API error')
      end
    end
  end

  describe '#rollback' do
    let(:command) { described_class.new }

    context 'when a buffer_post_id is present' do
      before do
        command.context.buffer_post_id = 'buffer_post_456'
      end

      it 'calls Buffer API to destroy the post' do
        expect(Buffer::Client).to receive(:new).and_return(buffer_client)
        expect(buffer_client).to receive(:destroy_post).with(buffer_post_id: 'buffer_post_456')
        command.rollback
      end

      context 'when destroy fails' do
        before do
          allow(buffer_client).to receive(:destroy_post).and_raise(Buffer::Client::Error, 'Destroy failed')
        end

        it 'logs the error but does not raise' do
          expect(Rails.logger).to receive(:error).with('Failed to rollback Buffer post buffer_post_456: Destroy failed')
          expect { command.rollback }.not_to raise_error
        end
      end
    end

    context 'when no buffer_post_id is present' do
      before do
        command.context.buffer_post_id = nil
      end

      it 'does not call Buffer API' do
        expect(Buffer::Client).not_to receive(:new)
        command.rollback
      end
    end
  end
end
