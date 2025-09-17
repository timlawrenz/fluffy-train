# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Personas do
  describe '.create' do
    context 'with valid data' do
      let(:name) { 'Clark Kent' }

      it 'returns a successful context' do
        result = described_class.create(name: name)
        expect(result).to be_success
      end

      it 'returns the created persona' do
        result = described_class.create(name: name)
        expect(result.persona).to be_a(Persona)
        expect(result.persona.name).to eq(name)
      end

      it 'creates a new persona record' do
        expect { described_class.create(name: name) }
          .to change(Persona, :count).by(1)
      end
    end

    context 'with invalid data' do
      let(:name) { 'Lois Lane' }

      before { create(:persona, name: name) }

      it 'returns a failure context' do
        result = described_class.create(name: name)
        expect(result).to be_failure
      end

      it 'does not create a new persona' do
        expect { described_class.create(name: name) }
          .not_to change(Persona, :count)
      end

      it 'includes an error message' do
        result = described_class.create(name: name)
        expect(result.full_error_message).to be_present
      end
    end
  end

  describe '.find' do
    let!(:persona) { create(:persona) }

    context 'when persona exists' do
      it 'returns the persona' do
        expect(described_class.find(persona.id)).to eq(persona)
      end
    end

    context 'when persona does not exist' do
      it 'returns nil' do
        expect(described_class.find(persona.id + 1)).to be_nil
      end
    end
  end
end
