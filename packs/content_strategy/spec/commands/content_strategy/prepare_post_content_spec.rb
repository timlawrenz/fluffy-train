# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentStrategy::PreparePostContent do
  let(:persona) { Persona.create!(name: 'test_persona') }
  let(:cluster) { Clustering::Cluster.create!(name: 'Test Cluster') }
  let(:photo) { Photo.create!(path: '/test/photo.jpg', persona: persona, cluster: cluster) }
  
  describe '#call' do
    context 'when persona has caption config' do
      before do
        persona.caption_config = {
          tone: 'casual',
          voice_attributes: ['witty'],
          style: { use_emoji: true, avg_length: 'medium' }
        }
        persona.save!
      end

      it 'generates AI caption' do
        allow_any_instance_of(ContentStrategy::SelectNextPost).to receive(:call).and_return(
          success: true,
          photo: photo,
          cluster: cluster,
          hashtags: ['#test', '#photography'],
          optimal_time: Time.current,
          format: 'single',
          strategy_name: 'test_strategy'
        )

        allow(CaptionGenerations::Generator).to receive(:generate).and_return(
          CaptionGenerations::Result.new(
            text: 'Great shot!',
            metadata: { model: 'llava:latest', quality_score: 8.0 }
          )
        )

        result = described_class.new(persona: persona).call

        expect(result[:success]).to be true
        expect(result[:caption]).to include('Great shot!')
        expect(result[:caption]).to include('#test')
        expect(result[:caption_metadata][:generated_by]).to eq('ai')
      end

      it 'falls back to photo analysis on error' do
        PhotoAnalysis.create!(photo: photo, caption: 'Fallback caption')

        allow_any_instance_of(ContentStrategy::SelectNextPost).to receive(:call).and_return(
          success: true,
          photo: photo,
          cluster: cluster,
          hashtags: ['#test'],
          optimal_time: Time.current,
          format: 'single',
          strategy_name: 'test_strategy'
        )

        allow(CaptionGenerations::Generator).to receive(:generate).and_raise(StandardError, 'AI error')

        result = described_class.new(persona: persona).call

        expect(result[:success]).to be true
        expect(result[:caption]).to include('Fallback caption')
        expect(result[:caption_metadata][:generated_by]).to eq('fallback')
        expect(result[:caption_metadata][:error]).to eq('AI error')
      end
    end

    context 'when persona has no caption config' do
      it 'uses photo analysis caption' do
        PhotoAnalysis.create!(photo: photo, caption: 'Photo caption')

        allow_any_instance_of(ContentStrategy::SelectNextPost).to receive(:call).and_return(
          success: true,
          photo: photo,
          cluster: cluster,
          hashtags: ['#test'],
          optimal_time: Time.current,
          format: 'single',
          strategy_name: 'test_strategy'
        )

        result = described_class.new(persona: persona).call

        expect(result[:success]).to be true
        expect(result[:caption]).to include('Photo caption')
        expect(result[:caption_metadata][:generated_by]).to eq('photo_analysis')
      end
    end

    context 'when generate_caption is false' do
      it 'uses photo analysis even with caption config' do
        persona.caption_config = { tone: 'casual' }
        persona.save!
        
        PhotoAnalysis.create!(photo: photo, caption: 'Photo caption')

        allow_any_instance_of(ContentStrategy::SelectNextPost).to receive(:call).and_return(
          success: true,
          photo: photo,
          cluster: cluster,
          hashtags: ['#test'],
          optimal_time: Time.current,
          format: 'single',
          strategy_name: 'test_strategy'
        )

        allow(CaptionGenerations::Generator).to receive(:generate)

        result = described_class.new(persona: persona, generate_caption: false).call

        expect(result[:success]).to be true
        expect(result[:caption]).to include('Photo caption')
        expect(CaptionGenerations::Generator).not_to have_received(:generate)
      end
    end

    context 'when photo selection fails' do
      it 'returns error from SelectNextPost' do
        allow_any_instance_of(ContentStrategy::SelectNextPost).to receive(:call).and_return(
          success: false,
          error: 'No photos available'
        )

        result = described_class.new(persona: persona).call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('No photos available')
      end
    end
  end
end
