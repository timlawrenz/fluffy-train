# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

RSpec.describe GenerateEmbedding, type: :command do
  let(:photo) { FactoryBot.create(:photo) }
  let(:embedding_vector) { [0.1] * 512 }

  describe 'interface' do
    it { is_expected.to require(:photo).being(Photo) }
    it { is_expected.to returns(:photo) }
  end

  describe '#call' do
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(photo.path).and_return(true)
    end

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
      before do
        allow(File).to receive(:exist?).with(photo.path).and_return(false)
      end

      it 'is a failure' do
        result = described_class.call(photo: photo)
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.call(photo: photo)
        expect(result.full_error_message).to eq("Photo file not found at path: #{photo.path}")
      end
    end

    context 'when ImageEmbedClient raises an error' do
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
