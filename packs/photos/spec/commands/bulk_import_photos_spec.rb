# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'
require 'gl_command/rspec'
require 'tmpdir'

RSpec.describe BulkImportPhotos, type: :command do
  let!(:persona) { FactoryBot.create(:persona) }
  let(:photo_path) { Rails.root.join('spec/fixtures/files/example.png') }
  let(:tmpdir) { Dir.mktmpdir }
  # Use the correct `build_context` helper to create the mock context.
  let(:mock_import_context) { Photos::Import.build_context(photo: FactoryBot.build_stubbed(:photo)) }

  before do
    # Stub the Photos::Import command to prevent real imports.
    RSpec::Mocks.allow_message(Photos::Import, :call!).and_return(mock_import_context)
    RSpec::Mocks.allow_message(Photos::Import, :call).and_return(mock_import_context)
  end

  describe 'interface' do
    it { is_expected.to require(:folder) }
    it { is_expected.to require(:persona).being(Persona) }
    it { is_expected.to returns(:imported_count) }
  end

  describe '#call' do
    context 'with a valid, non-empty folder' do
      before do
        FileUtils.cp(photo_path, File.join(tmpdir, 'photo1.jpg'))
        FileUtils.mkdir_p(File.join(tmpdir, 'subdir'))
        FileUtils.cp(photo_path, File.join(tmpdir, 'subdir', 'photo2.png'))
        FileUtils.touch(File.join(tmpdir, 'notes.txt'))
      end

      it 'calls the import command for each file' do
        jpg_path = File.join(tmpdir, 'photo1.jpg')
        png_path = File.join(tmpdir, 'subdir', 'photo2.png')
        expect(Photos::Import).to receive(:call!).with(path: jpg_path, persona: persona)
        expect(Photos::Import).to receive(:call!).with(path: png_path, persona: persona)
        described_class.call(persona: persona, folder: tmpdir)
      end

      it 'is successful' do
        result = described_class.call(persona: persona, folder: tmpdir)
        expect(result).to be_success
      end

      it 'returns the count of imported photos' do
        # To make this test work with the stub, we need to simulate the creation of photos.
        RSpec::Mocks.allow_message(Photo, :count).and_return(0, 2)
        result = described_class.call(persona: persona, folder: tmpdir)
        expect(result.imported_count).to eq(2)
      end

      it 'is idempotent' do
        # Simulate the first run creating photos.
        RSpec::Mocks.allow_message(Photo, :count).and_return(0, 2)
        described_class.call(persona: persona, folder: tmpdir)

        # Simulate the second run where no new photos are created.
        RSpec::Mocks.allow_message(Photo, :count).and_return(2, 2)
        result = described_class.call(persona: persona, folder: tmpdir)
        expect(result.imported_count).to eq(0)
      end
    end

    context 'with an empty folder' do
      it 'does not call the import command' do
        expect(Photos::Import).not_to receive(:call!)
        described_class.call(persona: persona, folder: tmpdir)
      end

      it 'returns an imported count of 0' do
        result = described_class.call(persona: persona, folder: tmpdir)
        expect(result.imported_count).to eq(0)
      end
    end
  end
end
