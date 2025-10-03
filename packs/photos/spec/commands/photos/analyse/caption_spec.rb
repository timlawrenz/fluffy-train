# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'
require 'tempfile'

module Photos
  # rubocop:disable Metrics/ModuleLength
  module Analyse
    RSpec.describe Caption, type: :command do
      let(:photo) { FactoryBot.create(:photo, path: tempfile.path) }
      let(:tempfile) { Tempfile.new(['test_photo', '.jpg']) }
      let(:generated_caption) { 'A beautiful sunset over the mountains.' }
      let(:mock_llm_client) do
        Class.new do
          def self.generate_caption(*)
            'A beautiful sunset over the mountains.'
          end
        end
      end
      let(:photo_analysis) { instance_double(PhotoAnalysis, caption: nil, save!: true) }

      after do
        tempfile.close
        tempfile.unlink
      end

      describe 'interface' do
        it { is_expected.to require(:photo).being(Photo) }
        it { is_expected.to allow(:llm_client) }
        it { is_expected.to returns(:caption) }
      end

      describe '#call' do
        context 'with a valid photo file and existing photo_analysis' do
          let(:photo_analysis) { instance_double(PhotoAnalysis, caption: nil, save!: true) }

          before do
            RSpec::Mocks.allow_message(photo, :photo_analysis).and_return(photo_analysis)
            RSpec::Mocks.allow_message(photo_analysis, :caption=)
            RSpec::Mocks.allow_message(photo_analysis, :save!)
          end

          it 'is successful' do
            result = described_class.call(photo: photo, llm_client: mock_llm_client)
            expect(result).to be_success
          end

          it 'returns the generated caption from the llm_client' do
            result = described_class.call(photo: photo, llm_client: mock_llm_client)
            expect(result.caption).to eq(generated_caption)
          end

          it 'calls the llm_client with the correct photo path' do
            expect(mock_llm_client).to receive(:generate_caption).with(file_path: photo.path)
            described_class.call(photo: photo, llm_client: mock_llm_client)
          end

          it 'saves the caption to the photo_analysis record' do
            expect(photo_analysis).to receive(:caption=).with(generated_caption)
            expect(photo_analysis).to receive(:save!)
            described_class.call(photo: photo, llm_client: mock_llm_client)
          end
        end

        context 'when photo_analysis does not exist' do
          let(:new_photo_analysis) { instance_double(PhotoAnalysis, caption: nil, save!: true) }

          before do
            RSpec::Mocks.allow_message(photo, :photo_analysis).and_return(nil)
            RSpec::Mocks.allow_message(photo, :build_photo_analysis).and_return(new_photo_analysis)
            RSpec::Mocks.allow_message(new_photo_analysis, :caption=)
            RSpec::Mocks.allow_message(new_photo_analysis, :save!)
          end

          it 'creates a new photo_analysis record' do
            RSpec::Mocks.allow_message(photo, :build_photo_analysis).and_return(new_photo_analysis)
            expect(new_photo_analysis).to receive(:caption=).with(generated_caption)
            expect(new_photo_analysis).to receive(:save!)

            result = described_class.call(photo: photo, llm_client: mock_llm_client)
            expect(result).to be_success
          end
        end

        context 'without a photo file' do
          before do
            photo.update(path: '/non/existent/file.jpg')
          end

          it 'fails' do
            result = described_class.call(photo: photo, llm_client: mock_llm_client)
            expect(result).to be_failure
          end

          it 'returns a helpful error message' do
            result = described_class.call(photo: photo, llm_client: mock_llm_client)
            expect(result.full_error_message).to eq("Photo file not found at path: #{photo.path}")
          end
        end

        context 'when the llm_client raises an OllamaClient::Error' do
          let(:error_message) { 'The model is offline' }
          let(:failing_llm_client) do
            Class.new do
              def self.generate_caption(*)
                raise OllamaClient::Error, 'The model is offline'
              end
            end
          end

          it 'fails' do
            result = described_class.call(photo: photo, llm_client: failing_llm_client)
            expect(result).to be_failure
          end

          it 'returns a helpful error message' do
            result = described_class.call(photo: photo, llm_client: failing_llm_client)
            expect(result.full_error_message).to eq("Failed to generate caption for image: #{error_message}")
          end
        end

        context 'when the llm_client raises an unexpected error' do
          let(:error_message) { 'Network timeout' }
          let(:failing_llm_client) do
            Class.new do
              def self.generate_caption(*)
                raise StandardError, 'Network timeout'
              end
            end
          end

          it 'fails' do
            result = described_class.call(photo: photo, llm_client: failing_llm_client)
            expect(result).to be_failure
          end

          it 'returns a helpful error message' do
            result = described_class.call(photo: photo, llm_client: failing_llm_client)
            expect(result.full_error_message).to eq("Unexpected error during caption generation: #{error_message}")
          end
        end

        context 'when saving the photo_analysis fails' do
          let(:photo_analysis) { instance_double(PhotoAnalysis, caption: nil) }

          before do
            RSpec::Mocks.allow_message(photo, :photo_analysis).and_return(photo_analysis)
            RSpec::Mocks.allow_message(photo_analysis, :caption=)
            RSpec::Mocks.allow_message(photo_analysis, :save!).and_raise(StandardError, 'Database error')
          end

          it 'fails' do
            result = described_class.call(photo: photo, llm_client: mock_llm_client)
            expect(result).to be_failure
          end

          it 'returns a helpful error message' do
            result = described_class.call(photo: photo, llm_client: mock_llm_client)
            expect(result.full_error_message).to eq('Unexpected error during caption generation: Database error')
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
