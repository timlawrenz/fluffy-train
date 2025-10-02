# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

module Scheduling
  # rubocop:disable Metrics/ModuleLength
  module Strategies
    RSpec.describe CuratorsChoice, type: :command do
      let!(:persona) { FactoryBot.create(:persona) }

      describe 'interface' do
        it { is_expected.to require(:persona).being(Persona) }
        it { is_expected.to returns(:selected_photo) }
      end

      describe 'constants' do
        it 'has a static caption constant' do
          expect(described_class::STATIC_CAPTION).to be_a(String)
          expect(described_class::STATIC_CAPTION).not_to be_empty
        end
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

          context 'with posting lifecycle management' do
            let(:mock_url_command) { instance_double('GeneratePublicPhotoUrl') } # rubocop:disable RSpec/VerifiedDoubleReference
            let(:mock_instagram_command) { instance_double('SendPostToInstagram') } # rubocop:disable RSpec/VerifiedDoubleReference
            let(:mock_url_result) do
              # rubocop:disable RSpec/VerifiedDoubleReference
              instance_double('URLResult', success?: true, public_photo_url: 'https://example.com/photo.jpg')
              # rubocop:enable RSpec/VerifiedDoubleReference
            end
            let(:mock_instagram_result) do
              # rubocop:disable RSpec/VerifiedDoubleReference
              instance_double('InstagramResult', success?: true, instagram_post_id: 'insta_123')
              # rubocop:enable RSpec/VerifiedDoubleReference
            end

            before do
              RSpec::Mocks.allow_message(Scheduling::Commands::GeneratePublicPhotoUrl,
                                         :call).and_return(mock_url_result)
              RSpec::Mocks.allow_message(Scheduling::Commands::SendPostToInstagram,
                                         :call).and_return(mock_instagram_result)
            end

            it 'creates a Scheduling::Post record with posting status when photo is selected' do
              expect do
                described_class.call(persona: persona)
              end.to change(Scheduling::Post, :count).by(1)

              post = Scheduling::Post.last
              expect(post.photo).to eq(higher_scored_photo)
              expect(post.persona).to eq(persona)
              expect(post.status).to eq('posted') # After successful posting
              expect(post.caption).to eq(described_class::STATIC_CAPTION)
            end

            it 'calls the Instagram API with correct parameters' do
              described_class.call(persona: persona)

              expect(Scheduling::Commands::GeneratePublicPhotoUrl).to have_received(:call)
                .with(photo: higher_scored_photo)
              expect(Scheduling::Commands::SendPostToInstagram).to have_received(:call).with(
                public_photo_url: 'https://example.com/photo.jpg',
                caption: described_class::STATIC_CAPTION,
                persona: persona
              )
            end

            it 'updates post status to posted with provider_post_id and posted_at on success' do
              described_class.call(persona: persona)

              post = Scheduling::Post.last
              expect(post.status).to eq('posted')
              expect(post.provider_post_id).to eq('insta_123')
              expect(post.posted_at).to be_present
              expect(post.posted_at).to be_within(1.minute).of(Time.current)
            end

            context 'when URL generation fails' do
              let(:mock_url_result) do
                # rubocop:disable RSpec/VerifiedDoubleReference
                instance_double('URLResult', success?: false, errors: ['URL generation failed'])
                # rubocop:enable RSpec/VerifiedDoubleReference
              end

              it 'marks post as failed' do
                described_class.call(persona: persona)

                post = Scheduling::Post.last
                expect(post.status).to eq('failed')
                expect(post.provider_post_id).to be_nil
                expect(post.posted_at).to be_nil
              end
            end

            context 'when Instagram API fails' do
              let(:mock_instagram_result) do
                # rubocop:disable RSpec/VerifiedDoubleReference
                instance_double('InstagramResult', success?: false, errors: ['API error'])
                # rubocop:enable RSpec/VerifiedDoubleReference
              end

              it 'marks post as failed' do
                described_class.call(persona: persona)

                post = Scheduling::Post.last
                expect(post.status).to eq('failed')
                expect(post.provider_post_id).to be_nil
                expect(post.posted_at).to be_nil
              end
            end
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
