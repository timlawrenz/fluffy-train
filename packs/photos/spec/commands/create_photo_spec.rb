# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'
require 'gl_command/rspec'

RSpec.describe CreatePhoto, type: :command do
  let!(:persona) { FactoryBot.create(:persona) }
  let(:test_image_path) { Rails.root.join('spec/fixtures/files/test_image.jpg') }

  describe 'interface' do
    it { is_expected.to require(:path) }
    it { is_expected.to require(:persona).being(Persona) }
    it { is_expected.to returns(:photo) }
  end

  describe '#call' do
    around do |example|
      FileUtils.mkdir_p(File.dirname(test_image_path))
      FileUtils.touch(test_image_path)
      example.run
      FileUtils.rm_f(test_image_path)
    end

    context 'with a valid path' do
      it 'creates a new photo record' do
        expect { described_class.call(path: test_image_path.to_s, persona: persona) }
          .to change(Photo, :count).by(1)
      end

      it 'is successful' do
        result = described_class.call(path: test_image_path.to_s, persona: persona)
        expect(result).to be_success
      end

      it 'returns the created photo' do
        result = described_class.call(path: test_image_path.to_s, persona: persona)
        expect(result.photo).to be_a(Photo)
        expect(result.photo.path).to eq(test_image_path.to_s)
        expect(result.photo.persona).to eq(persona)
      end

      it 'attaches the image file using ActiveStorage' do
        result = described_class.call(path: test_image_path.to_s, persona: persona)
        photo = result.photo
        
        expect(photo.image.attached?).to be true
        expect(photo.image.filename.to_s).to eq('test_image.jpg')
      end

      it 'is idempotent' do
        described_class.call(path: test_image_path.to_s, persona: persona)
        expect { described_class.call(path: test_image_path.to_s, persona: persona) }
          .not_to change(Photo, :count)
      end
    end

    context 'with a non-existent path' do
      let(:non_existent_path) { '/non/existent/path/image.jpg' }

      it 'creates a photo record even if file does not exist' do
        expect { described_class.call(path: non_existent_path, persona: persona) }
          .to change(Photo, :count).by(1)
      end

      it 'does not attach the image if file does not exist' do
        result = described_class.call(path: non_existent_path, persona: persona)
        photo = result.photo
        
        expect(photo.image.attached?).to be false
      end
    end
  end
end