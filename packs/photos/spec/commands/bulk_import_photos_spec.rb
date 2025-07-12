# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'
require 'gl_command/rspec'

RSpec.describe BulkImportPhotos, type: :command do
  let!(:persona) { FactoryBot.create(:persona) }

  describe 'interface' do
    it { is_expected.to require(:folder) }
    it { is_expected.to require(:persona).being(Persona) }
    it { is_expected.to returns(:imported_count) }
  end

  describe '#call' do
    around do |example|
      Dir.mktmpdir do |dir|
        @tmpdir = dir
        example.run
      end
    end

    context 'with a valid, non-empty folder' do
      before do
        FileUtils.touch(File.join(@tmpdir, 'photo1.jpg'))
        FileUtils.mkdir_p(File.join(@tmpdir, 'subdir'))
        FileUtils.touch(File.join(@tmpdir, 'subdir', 'photo2.png'))
        FileUtils.touch(File.join(@tmpdir, 'notes.txt'))
      end

      it 'creates new photo records for all files' do
        expect { described_class.call(persona: persona, folder: @tmpdir) }
          .to change(Photo, :count).by(2)
      end

      it 'is successful' do
        result = described_class.call(persona: persona, folder: @tmpdir)
        expect(result).to be_success
      end

      it 'returns the count of imported photos' do
        result = described_class.call(persona: persona, folder: @tmpdir)
        expect(result.imported_count).to eq(2)
      end

      it 'is idempotent' do
        described_class.call(persona: persona, folder: @tmpdir)
        expect { described_class.call(persona: persona, folder: @tmpdir) }
          .not_to change(Photo, :count)
        result = described_class.call(persona: persona, folder: @tmpdir)
        expect(result.imported_count).to eq(0)
      end
    end

    context 'with an empty folder' do
      it 'does not create any photo records' do
        expect { described_class.call(persona: persona, folder: @tmpdir) }
          .not_to change(Photo, :count)
      end

      it 'returns an imported count of 0' do
        result = described_class.call(persona: persona, folder: @tmpdir)
        expect(result.imported_count).to eq(0)
      end
    end

    context 'with a non-existent folder' do
      it 'is a failure' do
        result = described_class.call(persona: persona, folder: '/non/existent/path')
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.call(persona: persona, folder: '/non/existent/path')
        expect(result.full_error_message).to eq('Folder does not exist: /non/existent/path')
      end
    end
  end
end
