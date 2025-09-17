# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreatePersona, type: :command do
  describe 'interface' do
    it { is_expected.to require(:name) }
    it { is_expected.to returns(:persona) }
  end

  describe '#call' do
    context 'with a valid name' do
      let(:name) { 'Bugs Bunny' }

      it 'creates a Persona' do
        expect { described_class.call(name: name) }
          .to change(Persona, :count).by(1)
      end

      it 'is successful' do
        result = described_class.call(name: name)
        expect(result).to be_success
      end

      it 'returns the created persona' do
        result = described_class.call(name: name)
        expect(result.persona).to be_a(Persona)
        expect(result.persona.name).to eq(name)
      end
    end

    context 'with an invalid name' do
      before do
        create(:persona, name: 'Daffy Duck')
      end

      let(:name) { 'Daffy Duck' }

      it 'does not create a Persona' do
        expect { described_class.call(name: name) }
          .not_to change(Persona, :count)
      end

      it 'is a failure' do
        result = described_class.call(name: name)
        expect(result).to be_failure
      end

      it 'returns an error message' do
        result = described_class.call(name: name)
        expect(result.full_error_message).to eq('Name has already been taken')
      end
    end
  end

  describe '#rollback' do
    xit 'destroys the created persona' do
      command = described_class.new(name: 'Porky Pig')
      command.call
      expect(command).to be_success
      expect { command.rollback }.to change(Persona, :count).by(-1)
    end
  end
end
