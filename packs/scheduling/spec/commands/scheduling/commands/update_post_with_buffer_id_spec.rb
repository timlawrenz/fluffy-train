# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

RSpec.describe Scheduling::Commands::UpdatePostWithBufferId, type: :command do
  let(:post) { instance_double('Scheduling::Post', buffer_post_id: nil, status: 'draft') }
  let(:buffer_post_id) { 'buffer_post_456' }

  before do
    allow(post).to receive(:update!)
    allow(post).to receive(:schedule!)
  end

  describe 'interface' do
    it { is_expected.to require(:post) }
    it { is_expected.to require(:buffer_post_id) }
    it { is_expected.to returns(:post) }
  end

  describe '#call' do
    context 'with valid arguments' do
      it 'is successful' do
        result = described_class.call(
          post: post,
          buffer_post_id: buffer_post_id
        )
        expect(result).to be_success
      end

      it 'updates the post with buffer_post_id' do
        expect(post).to receive(:update!).with(buffer_post_id: buffer_post_id)
        described_class.call(
          post: post,
          buffer_post_id: buffer_post_id
        )
      end

      it 'triggers the schedule state transition' do
        expect(post).to receive(:schedule!)
        described_class.call(
          post: post,
          buffer_post_id: buffer_post_id
        )
      end

      it 'returns the updated post in context' do
        result = described_class.call(
          post: post,
          buffer_post_id: buffer_post_id
        )
        expect(result.post).to eq(post)
      end
    end

    context 'when update fails' do
      before do
        allow(post).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(post))
      end

      it 'is a failure' do
        result = described_class.call(
          post: post,
          buffer_post_id: buffer_post_id
        )
        expect(result).to be_failure
      end
    end

    context 'when state transition fails' do
      before do
        allow(post).to receive(:schedule!).and_raise(StateMachines::InvalidTransition.new(post, :status, :schedule))
      end

      it 'is a failure' do
        result = described_class.call(
          post: post,
          buffer_post_id: buffer_post_id
        )
        expect(result).to be_failure
      end
    end
  end

  describe '#rollback' do
    let(:command) { described_class.new }
    let(:original_status) { 'draft' }
    let(:original_buffer_post_id) { nil }

    before do
      command.context.post = post
      # Simulate the command having stored original values
      command.instance_variable_set(:@original_status, original_status)
      command.instance_variable_set(:@original_buffer_post_id, original_buffer_post_id)
    end

    context 'when a post is present' do
      it 'reverts the post to original state' do
        expect(post).to receive(:update!).with(
          status: original_status,
          buffer_post_id: original_buffer_post_id
        )
        command.rollback
      end
    end

    context 'when no post is present' do
      before do
        command.context.post = nil
      end

      it 'does not raise an error' do
        expect { command.rollback }.not_to raise_error
      end
    end

    context 'with different original values' do
      let(:original_status) { 'scheduled' }
      let(:original_buffer_post_id) { 'old_buffer_id' }

      it 'reverts to the correct original values' do
        expect(post).to receive(:update!).with(
          status: 'scheduled',
          buffer_post_id: 'old_buffer_id'
        )
        command.rollback
      end
    end
  end
end
