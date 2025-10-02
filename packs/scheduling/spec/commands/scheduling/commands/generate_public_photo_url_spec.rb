# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

RSpec.describe Scheduling::Commands::GeneratePublicPhotoUrl, type: :command do
  let(:photo) { FactoryBot.build_stubbed(:photo) }
  let(:image_attachment) { instance_double(ActiveStorage::Attached::One) }
  let(:public_url) { 'https://example.com/photo.jpg' }

  before do
    RSpec::Mocks.allow_message(photo, :image).and_return(image_attachment)
    RSpec::Mocks.allow_message(Rails.application.routes.url_helpers, :url_for).and_return(public_url)
  end

  describe 'interface' do
    it { is_expected.to require(:photo).being(Photo) }
    it { is_expected.to returns(:public_photo_url) }
  end

  describe '#call' do
    context 'when photo has an attached image' do
      before do
        RSpec::Mocks.allow_message(image_attachment, :attached?).and_return(true)
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

    context 'when photo has no attached image' do
      before do
        RSpec::Mocks.allow_message(image_attachment, :attached?).and_return(false)
      end

      it 'is a failure' do
        result = described_class.call(photo: photo)
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.call(photo: photo)
        expect(result.full_error_message).to eq('Photo must have an attached image')
      end
    end
  end

  describe '#rollback' do
    it 'does not have a custom rollback method' do
      rollback_method = described_class.instance_method(:rollback)
      expect(rollback_method.owner).to eq(GLCommand::Callable)
    end
  end
end
