# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateEmbeddingJob, type: :job do
  include ActiveJob::TestHelper

  let(:photo) { FactoryBot.create(:photo) }

  it 'calls Photos.generate_embedding' do
    expect(Photos).to receive(:generate_embedding).with(photo: photo)
    described_class.perform_now(photo.id)
  end

  it 'does nothing if photo is not found' do
    expect(Photos).not_to receive(:generate_embedding)
    described_class.perform_now(photo.id + 1)
  end
end
