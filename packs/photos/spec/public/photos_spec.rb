# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Photos do
  let!(:persona) { FactoryBot.create(:persona) }

  describe '.create' do
    context 'with valid data' do
      let(:path) { '/path/to/image.jpg' }

      it 'returns a successful context' do
        result = described_class.create(path: path, persona: persona)
        expect(result).to be_success
      end

      it 'returns the created photo' do
        result = described_class.create(path: path, persona: persona)
        expect(result.photo).to be_a(Photo)
        expect(result.photo.path).to eq(path)
        expect(result.photo.persona).to eq(persona)
      end

      it 'creates a new photo record' do
        expect { described_class.create(path: path, persona: persona) }
          .to change(Photo, :count).by(1)
      end
    end

    context 'with invalid data' do
      let(:path) { nil }

      it 'returns a failure context' do
        result = described_class.create(path: path, persona: persona)
        expect(result).to be_failure
      end

      it 'does not create a new photo' do
        expect { described_class.create(path: path, persona: persona) }
          .not_to change(Photo, :count)
      end

      it 'includes an error message' do
        result = described_class.create(path: path, persona: persona)
        expect(result.full_error_message).to be_present
      end
    end
  end

  describe '.find' do
    let!(:photo) { FactoryBot.create(:photo, persona: persona) }

    context 'when photo exists' do
      it 'returns the photo' do
        expect(described_class.find(photo.id)).to eq(photo)
      end
    end

    context 'when photo does not exist' do
      it 'returns nil' do
        expect(described_class.find(photo.id + 1)).to be_nil
      end
    end
  end
end
