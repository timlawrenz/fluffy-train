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

      before { FactoryBot.create(:persona, name: name) }

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
    let!(:persona) { FactoryBot.create(:persona) }

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

  describe '.list' do
    context 'when no personas exist' do
      it 'returns an empty array' do
        expect(described_class.list).to eq([])
      end

      it 'returns an Array' do
        expect(described_class.list).to be_a(Array)
      end
    end

    context 'when personas exist' do
      let!(:bruce_wayne) { FactoryBot.create(:persona, name: 'Bruce Wayne') }
      let!(:clark_kent) { FactoryBot.create(:persona, name: 'Clark Kent') }

      it 'returns all personas as an array' do
        result = described_class.list
        expect(result).to be_a(Array)
        expect(result).to contain_exactly(bruce_wayne, clark_kent)
      end

      it 'does not return an ActiveRecord::Relation' do
        result = described_class.list
        expect(result).not_to be_a(ActiveRecord::Relation)
      end
    end
  end

  describe '.find_by_name' do
    let!(:persona) { FactoryBot.create(:persona, name: 'Diana Prince') }

    context 'when persona exists with the given name' do
      it 'returns the persona' do
        result = described_class.find_by_name(name: 'Diana Prince')
        expect(result).to eq(persona)
      end
    end

    context 'when no persona exists with the given name' do
      it 'returns nil' do
        result = described_class.find_by_name(name: 'Unknown Hero')
        expect(result).to be_nil
      end
    end

    context 'when name is nil' do
      it 'returns nil' do
        result = described_class.find_by_name(name: nil)
        expect(result).to be_nil
      end
    end

    context 'when name is empty string' do
      it 'returns nil' do
        result = described_class.find_by_name(name: '')
        expect(result).to be_nil
      end
    end
  end
end
