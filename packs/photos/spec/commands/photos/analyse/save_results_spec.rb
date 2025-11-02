require 'rails_helper'

RSpec.describe Photos::Analyse::SaveResults do
  describe '#call' do
    let(:photo) { FactoryBot.create(:photo) }
    let(:sharpness_score) { 0.8 }
    let(:exposure_score) { 0.7 }
    let(:aesthetic_score) { 0.9 }
    let(:detected_objects) { [{ 'label' => 'cat', 'confidence' => 0.9 }] }

    context 'with valid inputs' do
      it 'is successful' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).to be_success
      end

      it 'creates a PhotoAnalysis record' do
        expect do
          described_class.call(
            photo: photo,
            sharpness_score: sharpness_score,
            exposure_score: exposure_score,
            aesthetic_score: aesthetic_score,
            detected_objects: detected_objects
          )
        end.to change(PhotoAnalysis, :count).by(1)
      end

      it 'returns the created PhotoAnalysis record' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result.photo_analysis).to be_a(PhotoAnalysis)
        expect(result.photo_analysis.sharpness_score).to eq(sharpness_score)
        expect(result.photo_analysis.exposure_score).to eq(exposure_score)
        expect(result.photo_analysis.aesthetic_score).to eq(aesthetic_score)
        expect(result.photo_analysis.detected_objects).to eq(detected_objects)
      end
    end

    context 'when database operation fails' do
      before do
        allow_any_instance_of(PhotoAnalysis).to receive(:save!).and_raise(StandardError, 'Database error')
      end

      it 'fails' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result).not_to be_success
      end

      it 'returns an error message' do
        result = described_class.call(
          photo: photo,
          sharpness_score: sharpness_score,
          exposure_score: exposure_score,
          aesthetic_score: aesthetic_score,
          detected_objects: detected_objects
        )
        expect(result.full_error_message).to include('Database error')
      end
    end
  end
end
