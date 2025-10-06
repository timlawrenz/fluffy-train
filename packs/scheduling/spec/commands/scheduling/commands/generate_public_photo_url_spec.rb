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
        allow(Rails.application.routes.url_helpers).to receive(:url_for).with(image_attachment).and_return(public_url)
      end

      it 'is successful' do
        result = described_class.call(photo: photo)
        expect(result).to be_success
      end

      it 'generates a public URL for the photo' do
        expect(Rails.application.routes.url_helpers).to receive(:url_for).with(image_attachment)
        described_class.call(photo: photo)
      end

      it 'sets the public_photo_url in context' do
        result = described_class.call(photo: photo)
        expect(result.public_photo_url).to eq(public_url)
      end
    end

    context 'when photo does not have an attached image' do
      before do
        allow(photo).to receive(:is_a?).with(Photo).and_return(true)
        allow(photo).to receive(:image).and_return(nil)
      end

      it 'fails' do
        result = described_class.call(photo: photo)
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.call(photo: photo)
        expect(result.errors.full_messages).to include('Photo does not have an attached image')
      end
    end

    context 'when photo is not a Photo object' do
      it 'fails' do
        result = described_class.call(photo: 'not a photo')
        expect(result).to be_failure
      end
    end
  end
end