# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

RSpec.describe Scheduling::Commands::GeneratePublicPhotoUrl, type: :command do
  let(:photo) { instance_double('Photo') }
  let(:image_attachment) { instance_double('ActiveStorage::Attached::One') }
  let(:public_url) { 'https://example.com/photo.jpg' }

  before do
    allow(photo).to receive(:image).and_return(image_attachment)
    allow(Rails.application.routes.url_helpers).to receive(:url_for).and_return(public_url)
  end

  describe 'interface' do
    it { is_expected.to require(:photo) }
    it { is_expected.to returns(:public_photo_url) }
  end

  describe '#call' do
    context 'when photo has an attached image' do
      before do
        allow(image_attachment).to receive(:attached?).and_return(true)
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
        allow(image_attachment).to receive(:attached?).and_return(false)
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
    let(:command) { described_class.new }

    it 'does not define a rollback method (read-only operation)' do
      # This command is read-only and should not have a rollback method
      expect(command).not_to respond_to(:rollback)
    end
  end
end
