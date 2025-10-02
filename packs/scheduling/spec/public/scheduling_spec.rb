# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scheduling do
  let!(:persona) { FactoryBot.create(:persona) }
  let!(:first_photo) { FactoryBot.create(:photo, persona: persona) }
  let!(:second_photo) { FactoryBot.create(:photo, persona: persona) }
  let!(:third_photo) { FactoryBot.create(:photo, persona: persona) }

  describe '.unscheduled_for_persona' do
    context 'when no photos are scheduled' do
      it 'returns all photos for the persona' do
        result = described_class.unscheduled_for_persona(persona: persona)
        expect(result).to be_an(Array)
        expect(result).to contain_exactly(first_photo, second_photo, third_photo)
      end

      it 'returns Photos::Photo objects' do
        result = described_class.unscheduled_for_persona(persona: persona)
        expect(result).to all(be_a(Photo))
      end
    end

    context 'when some photos are scheduled' do
      before do
        FactoryBot.create(:scheduling_post, photo: first_photo, persona: persona)
        FactoryBot.create(:scheduling_post, photo: second_photo, persona: persona)
      end

      it 'returns only unscheduled photos' do
        result = described_class.unscheduled_for_persona(persona: persona)
        expect(result).to contain_exactly(third_photo)
      end
    end

    context 'when all photos are scheduled' do
      before do
        FactoryBot.create(:scheduling_post, photo: first_photo, persona: persona)
        FactoryBot.create(:scheduling_post, photo: second_photo, persona: persona)
        FactoryBot.create(:scheduling_post, photo: third_photo, persona: persona)
      end

      it 'returns an empty array' do
        result = described_class.unscheduled_for_persona(persona: persona)
        expect(result).to eq([])
      end
    end

    context 'with multiple personas' do
      let!(:other_persona) { FactoryBot.create(:persona) }
      let!(:other_photo) { FactoryBot.create(:photo, persona: other_persona) }

      before do
        FactoryBot.create(:scheduling_post, photo: first_photo, persona: persona)
        FactoryBot.create(:scheduling_post, photo: other_photo, persona: other_persona)
      end

      it 'returns only unscheduled photos for the specific persona' do
        result = described_class.unscheduled_for_persona(persona: persona)
        expect(result).to contain_exactly(second_photo, third_photo)
        expect(result).not_to include(other_photo)
      end
    end
  end

  describe '.schedule_post' do
    let(:caption) { 'Test caption' }

    it 'returns a GLCommand::Context' do
      result = described_class.schedule_post(photo: first_photo, persona: persona, caption: caption)
      expect(result).to be_a(GLCommand::Context)
    end
  end

  describe '.sync_post_statuses' do
    it 'returns a GLCommand::Context' do
      result = described_class.sync_post_statuses(persona: persona)
      expect(result).to be_a(GLCommand::Context)
    end

    it 'returns a successful context with empty updated_posts' do
      result = described_class.sync_post_statuses(persona: persona)
      expect(result).to be_success
      expect(result.updated_posts).to eq([])
    end
  end
end
