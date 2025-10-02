# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

module Scheduling
  module Strategies
    RSpec.describe CuratorsChoice, type: :command do
      let!(:persona) { FactoryBot.create(:persona) }

      describe 'interface' do
        it { is_expected.to require(:persona).being(Persona) }
        it { is_expected.to returns(:selected_photo) }
      end

      describe '#call' do
        context 'when no photos exist' do
          it 'returns nil and logs a warning' do
            result = described_class.call(persona: persona)

            expect(result).to be_success
            expect(result.selected_photo).to be_nil
          end
        end

        context 'when photos exist but none have analysis' do
          before do
            FactoryBot.create(:photo, persona: persona)
          end

          it 'returns nil and logs a warning' do
            result = described_class.call(persona: persona)

            expect(result).to be_success
            expect(result.selected_photo).to be_nil
          end
        end

        context 'when photos with analysis exist but all are posted' do
          before do
            photo = FactoryBot.create(:photo, persona: persona)
            FactoryBot.create(:photo_analysis, photo: photo, aesthetic_score: 8.5)
            FactoryBot.create(:scheduling_post, photo: photo, persona: persona)
          end

          it 'returns nil and logs a warning' do
            result = described_class.call(persona: persona)

            expect(result).to be_success
            expect(result.selected_photo).to be_nil
          end
        end

        context 'when unposted photos with analysis exist' do
          let!(:lower_scored_photo) { FactoryBot.create(:photo, persona: persona) }
          let!(:higher_scored_photo) { FactoryBot.create(:photo, persona: persona) }

          before do
            FactoryBot.create(:photo_analysis, photo: lower_scored_photo, aesthetic_score: 7.5)
            FactoryBot.create(:photo_analysis, photo: higher_scored_photo, aesthetic_score: 9.0)
          end

          it 'returns the photo with the highest aesthetic score' do
            result = described_class.call(persona: persona)

            expect(result).to be_success
            expect(result.selected_photo).to eq(higher_scored_photo)
          end
        end
      end
    end
  end
end
