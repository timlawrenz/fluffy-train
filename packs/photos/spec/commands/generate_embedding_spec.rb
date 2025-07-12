# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateEmbedding, type: :command do
  let(:temp_file_path) { Rails.root.join('spec/fixtures/files/temp_test_image.jpg') }
  let(:photo) { FactoryBot.create(:photo, path: temp_file_path) }
  let(:embedding_vector) { [0.1] * 512 }

  around do |example|
    FileUtils.mkdir_p(File.dirname(temp_file_path))
    FileUtils.touch(temp_file_path)
    example.run
    FileUtils.rm_f(temp_file_path)
  end

  describe 'interface' do
    it { is_expected.to require(:photo).being(Photo) }
    it { is_expected.to returns(:photo) }
  end

  describe '#call' do
    context 'when photo does not have an embedding' do
      before do
        photo.update_column(:embedding, nil)
        allow(ImageEmbedClient).to receive(:generate_embedding).with(file_path: photo.path).and_return(embedding_vector)
      end

      it 'is successful' do
        result = described_class.call(photo: photo)
        expect(result).to be_success
      end

      it 'updates the photo with the new embedding' do
        described_class.call(photo: photo)
        photo.reload
        expect(photo.embedding).to eq(embedding_vector)
      end

      it 'returns the updated photo' do
        result = described_class.call(photo: photo)
        expect(result.photo).to eq(photo)
        expect(result.photo.embedding).to eq(embedding_vector)
      end
    end

    context 'when photo already has an embedding' do
      before do
        photo.update_column(:embedding, embedding_vector)
      end

      it 'does not call the ImageEmbedClient' do
        expect(ImageEmbedClient).not_to receive(:generate_embedding)
        described_class.call(photo: photo)
      end

      it 'returns the photo without changes' do
        result = described_class.call(photo: photo)
        expect(result).to be_success
        expect(result.photo).to eq(photo)
        expect(result.photo.embedding).to eq(embedding_vector)
      end
    end

    context 'when image file does not exist' do
      it 'is a failure' do
        non_existent_photo = FactoryBot.create(:photo, path: '/path/to/non_existent_file.jpg')
        result = described_class.call(photo: non_existent_photo)
        expect(result).to be_failure
      end

      it 'returns an error message' do
        non_existent_photo = FactoryBot.create(:photo, path: '/path/to/non_existent_file.jpg')
        result = described_class.call(photo: non_existent_photo)
        expect(result.full_error_message).to eq("Photo file not found at path: #{non_existent_photo.path}")
      end
    end

    context 'when ImageEmbedClient raises an error' do
        result = described_class.call(photo: photo)
        expect(result).to be_failure
      end

      before do
        allow(ImageEmbedClient).to receive(:generate_embedding).and_raise(ImageEmbedClient::Error.new('API timeout'))
      end

      it 'is a failure' do
        result = described_class.call(photo: photo)
        expect(result).to be_failure
      end

      it 'returns an error message from the client' do
        result = described_class.call(photo: photo)
        expect(result.full_error_message).to eq('Failed to generate embedding: API timeout')
      end
    end
  end
end
