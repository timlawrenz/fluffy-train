require 'rails_helper'

RSpec.describe Photos::Analyse::SaveResults do
  describe '#call' do
    let(:photo) { instance_double(Photo, id: 1) }
    let(:sharpness_score) { 0.8 }
    let(:exposure_score) { 0.7 }
    let(:aesthetic_score) { 0.9 }
    let(:detected_objects) { { 'cat' => 0.9, 'dog' => 0.8 } }
    let(:caption) { 'A test caption' }
    let(:context) do
      GLCommand::Context.new.tap do |c|
        c.caption = caption
      end
    end
    let(:photo_analysis_association) { double('photo_analysis_association') }
    let(:created_photo_analysis) { instance_double('Photos::PhotoAnalysis') }

    before do
      allow(photo).to receive(:photo_analysis).and_return(photo_analysis_association)
    end

    context 'with valid inputs' do
      before do
        allow(photo_analysis_association).to receive(:create!).and_return(created_photo_analysis)
      end

      it 'is successful' do
        result = described_class.call(
          context,
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_success
      end

      it 'creates a PhotoAnalysis record' do
        expect(photo_analysis_association).to receive(:create!).with(
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects,
          caption: caption
        )

        described_class.call(
          context,
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
      end

      it 'returns the created PhotoAnalysis record' do
        result = described_class.call(
          context,
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result.photo_analysis).to eq(created_photo_analysis)
      end
    end

    context 'when database operation fails' do
      before do
        allow(photo_analysis_association).to receive(:create!).and_raise(StandardError, 'Database error')
      end

      it 'fails' do
        result = described_class.call(
          context,
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.call(
          context,
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result.errors.full_messages).to include('Base Database error')
      end
    end
  end
end
