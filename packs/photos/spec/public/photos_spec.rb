# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Photos do
  let!(:persona) { FactoryBot.create(:persona) }
  let(:photo_path) { Rails.root.join('spec', 'fixtures', 'files', 'example.png') }
  # Use the correct `build_context` helper to create the mock context.
  let(:mock_import_context) { Photos::Import.build_context(photo: FactoryBot.build_stubbed(:photo)) }

  before do
    # Stub the Photos::Import command to prevent real imports and speed up the tests.
    RSpec::Mocks.allow_message(Photos::Import, :call).and_return(mock_import_context)
  end

  describe '.create' do
    context 'with valid data' do
      it 'returns a successful context' do
        result = described_class.create(path: photo_path, persona: persona)
        expect(result).to be_a(GLCommand::Context)
        expect(result).to be_success
      end

      it 'calls the Import command' do
        expect(Photos::Import).to receive(:call).with(path: photo_path, persona: persona)
        described_class.create(path: photo_path, persona: persona)
      end

      it 'returns the created photo in the context' do
        result = described_class.create(path: photo_path, persona: persona)
        expect(result.photo).to be_a(Photo)
      end
    end

    context 'when Import command fails' do
      let(:mock_import_context) { Photos::Import.build_context(error: 'Import failed') }

      it 'returns a failed context' do
        result = described_class.create(path: photo_path, persona: persona)
        expect(result).to be_failure
      end
    end
  end

  describe '.find' do
    let!(:photo) { FactoryBot.create(:photo) }

    before do
      # Unstub the `call` method for this describe block.
      RSpec::Mocks.allow_message(Photos::Import, :call).and_call_original
    end

    it 'finds a photo by its ID' do
      found_photo = described_class.find(photo.id)
      expect(found_photo).to eq(photo)
    end

    it 'returns nil if no photo is found' do
      found_photo = described_class.find(photo.id + 1)
      expect(found_photo).to be_nil
    end
  end
end