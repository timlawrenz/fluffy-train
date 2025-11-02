require 'rails_helper'

RSpec.describe Scheduling::Commands::GeneratePublicPhotoUrl do
  describe '#call' do
    let(:photo) { instance_double(Photo) }

    context 'when photo has an attached image' do
      let(:image_attachment) { double('ActiveStorage::Attached::One') }
      let(:public_url) { 'https://example.com/photo.jpg' }

      before do
        allow(photo).to receive(:is_a?).with(Photo).and_return(true)
        allow(photo).to receive(:image).and_return(image_attachment)
        allow(image_attachment).to receive(:attached?).and_return(true)
        allow(image_attachment).to receive(:url).and_return(public_url)
      end

      it 'is successful' do
        result = described_class.call(photo: photo)
        expect(result).to be_success
      end

      it 'generates a public URL for the photo' do
        expect(image_attachment).to receive(:url)
        described_class.call(photo: photo)
      end

      it 'sets the public_photo_url in context' do
        result = described_class.call(photo: photo)
        expect(result.public_photo_url).to eq(public_url)
      end
    end

    context 'when photo does not have an attached image' do
      let(:image_attachment) { double('ActiveStorage::Attached::One') }

      before do
        allow(photo).to receive(:is_a?).with(Photo).and_return(true)
        allow(photo).to receive(:image).and_return(image_attachment)
        allow(image_attachment).to receive(:attached?).and_return(false)
      end

      it 'fails' do
        result = described_class.call(photo: photo)
        expect(result).not_to be_success
      end

      it 'returns an error message' do
        result = described_class.call(photo: photo)
        expect(result.full_error_message).to include('Photo must have an attached image')
      end
    end

    context 'when photo is not a Photo object' do
      it 'fails' do
        result = described_class.call(photo: 'not a photo')
        expect(result).not_to be_success
      end
    end
  end
end