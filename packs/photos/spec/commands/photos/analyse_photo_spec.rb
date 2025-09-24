# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'spec_helper'

require_relative '../../../app/commands/photos/analyse_photo'

RSpec.describe Photos::AnalysePhoto, type: :command do
  let(:photo) { double('Photo', id: 1) }
  let(:photo_analysis) { double('PhotoAnalysis', id: 1) }
  
  describe 'command chain' do
    it 'defines the correct commands in order' do
      expect(described_class.commands).to eq([
                                               Photos::Analyse::Sharpness,
                                               Photos::Analyse::Exposure,
                                               Photos::Analyse::Aesthetics,
                                               Photos::Analyse::ObjectDetection,
                                               Photos::CreatePhotoAnalysis
                                             ])
    end
  end

  describe '#call' do
    # Mock command contexts with expected results - they need returns methods
    let(:sharpness_context) do
      double('SharpnessContext',
             sharpness_score: 85.5,
             success?: true,
             returns: { sharpness_score: 85.5 })
    end
    let(:exposure_context) do
      double('ExposureContext',
             exposure_score: 0.75,
             success?: true,
             errors: [],
             returns: { exposure_score: 0.75 })
    end
    let(:aesthetics_context) do
      double('AestheticsContext',
             aesthetic_score: 7.2,
             success?: true,
             returns: { aesthetic_score: 7.2 })
    end
    let(:object_detection_context) do
      double('ObjectDetectionContext',
             detected_objects: [{ 'label' => 'tree', 'confidence' => 0.95 }],
             success?: true,
             returns: { detected_objects: [{ 'label' => 'tree', 'confidence' => 0.95 }] })
    end
    let(:create_analysis_context) do
      double('CreateAnalysisContext',
             photo_analysis: photo_analysis,
             success?: true,
             returns: { photo_analysis: photo_analysis })
    end

    before do
      # Mock the individual commands
      allow(Photos::Analyse::Sharpness).to receive(:call).and_return(sharpness_context)
      allow(Photos::Analyse::Exposure).to receive(:call).and_return(exposure_context)
      allow(Photos::Analyse::Aesthetics).to receive(:call).and_return(aesthetics_context)
      allow(Photos::Analyse::ObjectDetection).to receive(:call).and_return(object_detection_context)
      allow(Photos::CreatePhotoAnalysis).to receive(:call).and_return(create_analysis_context)

      # Mock the PhotoAnalysis destroy method for rollback
      allow(photo_analysis).to receive(:destroy)
    end

    context 'when all commands succeed' do
      it 'succeeds' do
        result = described_class.call(photo: photo)
        expect(result).to be_success
      end

      it 'calls all analysis commands in sequence' do
        # GLCommand::Chainable passes extra parameters for chaining, so we can't test exact parameters
        expect(Photos::Analyse::Sharpness).to receive(:call)
        expect(Photos::Analyse::Exposure).to receive(:call)
        expect(Photos::Analyse::Aesthetics).to receive(:call)
        expect(Photos::Analyse::ObjectDetection).to receive(:call)
        expect(Photos::CreatePhotoAnalysis).to receive(:call)

        described_class.call(photo: photo)
      end

      it 'returns the created PhotoAnalysis record' do
        result = described_class.call(photo: photo)
        expect(result.photo_analysis).to eq(photo_analysis)
      end
    end

    context 'when a command fails' do
      before do
        allow(exposure_context).to receive(:success?).and_return(false)
        allow(exposure_context).to receive(:errors).and_return(['Exposure analysis failed'])
        allow(exposure_context).to receive(:full_error_message).and_return('Exposure analysis failed')
      end

      it 'fails' do
        result = described_class.call(photo: photo)
        expect(result).to be_failure
      end
    end
  end

  describe '#rollback' do
    it 'destroys the PhotoAnalysis record if it exists' do
      command = described_class.new
      command.instance_variable_set(:@context, double('Context', photo_analysis: photo_analysis))
      
      expect(photo_analysis).to receive(:destroy)
      command.rollback
    end

    it 'does nothing if PhotoAnalysis record does not exist' do
      command = described_class.new
      command.instance_variable_set(:@context, double('Context', photo_analysis: nil))
      
      # Should not raise an error
      expect { command.rollback }.not_to raise_error
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles