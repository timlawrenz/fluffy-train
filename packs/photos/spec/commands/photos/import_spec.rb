# frozen_string_literal: true

require 'spec_helper'
require 'gl_command/rspec'

require_relative '../../../app/commands/photos/import'

RSpec.describe Photos::Import, type: :command do
  describe 'interface' do
    it { is_expected.to require(:path, persona: Persona) }
    it { is_expected.to returns(:photo, :photo_analysis) }
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

    it 'includes CreatePhoto and Photos::AnalysePhoto in correct order' do
      expect(described_class.commands).to eq([
                                               CreatePhoto,
                                               Photos::AnalysePhoto
                                             ])
    end
  end

  describe '#call' do
    # Test basic instantiation without complex mocking for now
    let(:persona) { double('Persona', id: 1) } # rubocop:disable RSpec/VerifiedDoubles
    let(:path) { '/tmp/test.jpg' }

    it 'can be instantiated' do
      expect { described_class.new }.not_to raise_error
    end
  end
end
