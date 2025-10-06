# frozen_string_literal: true

require 'spec_helper'
require 'gl_command/rspec'

require_relative '../../../app/commands/photos/analyse_photo'

RSpec.describe Photos::AnalysePhoto, type: :command do
  describe 'interface' do
    it { is_expected.to require(:photo) }
    it { is_expected.to returns(:photo_analysis) }
  end

  describe 'inheritance' do
    it 'inherits from GLCommand::Chainable' do
      expect(described_class).to be < GLCommand::Chainable
    end
  end

  describe 'command chain' do
    it 'has defined chain commands' do
      # Get chain from GLCommand::Chainable internals
      chain_commands = described_class.commands || []
      expect(chain_commands).not_to be_empty
    end

    it 'includes all required analysis commands in correct order' do
      expect(described_class.commands).to eq([
                                               Photos::Analyse::Sharpness,
                                               Photos::Analyse::Exposure,
                                               Photos::Analyse::Aesthetics,
                                               Photos::Analyse::ObjectDetection,
                                               Photos::Analyse::Caption,
                                               Photos::Analyse::SaveResults
                                             ])
    end
  end

  describe '#call' do
    # Test basic instantiation without complex mocking for now
    let(:photo) { double('Photo', id: 1, path: '/tmp/test.jpg') } # rubocop:disable RSpec/VerifiedDoubles

    it 'can be instantiated' do
      expect { described_class.new }.not_to raise_error
    end
  end
end
