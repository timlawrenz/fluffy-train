# frozen_string_literal: true

require 'rails_helper'
require 'gl_command/rspec'

module Scheduling
  module Strategies
    class URLResult
      def success?
        true
      end

      def public_photo_url
        ''
      end

      def errors
        []
      end
    end

    class InstagramResult
      def success?
        true
      end

      def instagram_post_id
        ''
      end

      def errors
        []
      end
    end

    RSpec.describe CuratorsChoice do
      let!(:persona) { FactoryBot.create(:persona) }

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
            FactoryBot.create(:photo_analysis, photo: lower_scored_photo, aesthetic_score: 7.5,
                                               caption: 'Lower scored photo caption')
            FactoryBot.create(:photo_analysis, photo: higher_scored_photo, aesthetic_score: 9.0,
                                               caption: 'Higher scored photo caption')
          end

          it 'returns the photo with the highest aesthetic score' do
            result = described_class.call(persona: persona)

            expect(result).to be_success
            expect(result.selected_photo).to eq(higher_scored_photo)
          end

          context 'with posting lifecycle management' do
            let(:mock_url_command) { class_double(Scheduling::Commands::GeneratePublicPhotoUrl).as_stubbed_const }
            let(:mock_instagram_command) { class_double(Scheduling::Commands::SendPostToInstagram).as_stubbed_const }
            let(:mock_url_result) do
              instance_double(URLResult, success?: true, public_photo_url: 'https://example.com/photo.jpg')
            end
            let(:mock_instagram_result) do
              instance_double(InstagramResult, success?: true, instagram_post_id: 'insta_123')
            end

            before do
              allow(mock_url_command).to receive(:call).and_return(mock_url_result)
              allow(mock_instagram_command).to receive(:call).and_return(mock_instagram_result)
            end

            it 'creates a Scheduling::Post record with posting status when photo is selected' do
              expect do
                described_class.call(persona: persona)
              end.to change(Scheduling::Post, :count).by(1)

              post = Scheduling::Post.last
              expect(post.photo).to eq(higher_scored_photo)
              expect(post.persona).to eq(persona)
              expect(post.status).to eq('posted') # After successful posting
              expect(post.caption).to eq('Higher scored photo caption')
            end

            it 'calls the Instagram API with correct parameters' do
              described_class.call(persona: persona)

              expect(mock_url_command).to have_received(:call)
                .with(photo: higher_scored_photo)
              expect(mock_instagram_command).to have_received(:call).with(
                public_photo_url: 'https://example.com/photo.jpg',
                caption: 'Higher scored photo caption',
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
              let(:mock_url_result) { instance_double(URLResult, success?: false, errors: ['URL generation failed']) }

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
                instance_double(InstagramResult, success?: false, errors: ['API error'])
              end

              it 'marks post as failed' do
                described_class.call(persona: persona)

                post = Scheduling::Post.last
                expect(post.status).to eq('failed')
                expect(post.provider_post_id).to be_nil
                expect(post.posted_at).to be_nil
              end
            end

            context 'when photo has no caption' do
              before do
                # Create photo analysis without caption
                higher_scored_photo.photo_analysis.update!(caption: nil)
              end

              it 'creates a Scheduling::Post record with nil caption' do
                expect do
                  described_class.call(persona: persona)
                end.to change(Scheduling::Post, :count).by(1)

                post = Scheduling::Post.last
                expect(post.caption).to be_nil
              end

              it 'calls the Instagram API with nil caption' do
                described_class.call(persona: persona)

                expect(mock_instagram_command).to have_received(:call).with(
                  public_photo_url: 'https://example.com/photo.jpg',
                  caption: nil,
                  persona: persona
                )
              end
            end
          end
        end
      end
    end
  end
end
