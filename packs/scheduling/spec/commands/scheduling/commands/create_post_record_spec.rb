# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

RSpec.describe Scheduling::Commands::CreatePostRecord, type: :command do
  let(:photo) { instance_double(Photo, id: 1) }
  let(:persona) { instance_double(Persona, id: 1) }
  let(:caption) { 'Test caption for the post' }
  let(:created_post) { instance_double(Scheduling::Post, id: 1, destroy!: true) }

  before do
    allow(Scheduling::Post).to receive(:create!).and_return(created_post)
  end

  describe 'interface' do
    it { is_expected.to require(:photo).being(Photo) }
    it { is_expected.to require(:persona).being(Persona) }
    it { is_expected.to require(:caption).being(String) }
    it { is_expected.to returns(:post).being(Scheduling::Post) }
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
        expect(Scheduling::Post).to receive(:create!).with(
          photo: photo,
          persona: persona,
          caption: caption,
          status: 'draft'
        )

        described_class.call(
          photo: photo,
          persona: persona,
          caption: caption
        )
      end

      it 'sets the created post in context' do
        result = described_class.call(
          photo: photo,
          persona: persona,
          caption: caption
        )
        expect(result.post).to eq(created_post)
      end
    end

    context 'when post creation fails' do
      before do
        allow(Scheduling::Post).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(created_post))
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
    let(:command) { described_class.new }

    context 'when a post was created' do
      it 'destroys the created post' do
        command.context.post = created_post
        expect(created_post).to receive(:destroy!)
        command.rollback
      end
    end

    context 'when no post was created' do
      it 'does not raise an error' do
        command.context.post = nil
        expect { command.rollback }.not_to raise_error
      end
    end
  end
end
