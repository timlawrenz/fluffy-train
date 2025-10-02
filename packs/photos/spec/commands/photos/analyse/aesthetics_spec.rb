# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

module Photos
  module Analyse
    RSpec.describe Aesthetics, type: :command do
      let(:photo) { FactoryBot.create(:photo) }
      let(:mock_llm_client) do
        Class.new do
          def self.get_aesthetic_score(file_path:)
            85
          end
        end
      end

      describe 'interface' do
        it { is_expected.to require(:photo).being(Photo) }
        it { is_expected.to allow(:llm_client) }
        it { is_expected.to returns(:aesthetic_score) }
      end

      describe '#call' do
        context 'with a valid photo file' do
          it 'is successful' do
            result = described_class.call(photo: photo, llm_client: mock_llm_client)
            expect(result).to be_success
          end

          it 'returns the aesthetic score from the llm_client' do
            result = described_class.call(photo: photo, llm_client: mock_llm_client)
            expect(result.aesthetic_score).to eq(85)
          end

          it 'calls the llm_client with the correct photo path' do
            expect(mock_llm_client).to receive(:get_aesthetic_score).with(file_path: photo.path)
            described_class.call(photo: photo, llm_client: mock_llm_client)
          end
        end

        context 'without a photo file' do
          before do
            allow(File).to receive(:exist?).with(photo.path).and_return(false)
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

        context 'when the llm_client raises an error' do
          let(:error_message) { 'The model is offline' }
          let(:failing_llm_client) do
            Class.new do
              def self.get_aesthetic_score(file_path:)
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
            expect(result.full_error_message).to eq("Failed to get aesthetic score for image: #{error_message}")
          end
        end
      end
    end
  end
end