# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Persona, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      persona = build(:persona)
      expect(persona).to be_valid
    end

    it 'is not valid without a name' do
      persona = build(:persona, name: nil)
      expect(persona).not_to be_valid
      expect(persona.errors[:name]).to include("can't be blank")
    end

    it 'is not valid with a duplicate name' do
      create(:persona, name: 'Satoshi')
      persona = build(:persona, name: 'Satoshi')
      expect(persona).not_to be_valid
      expect(persona.errors[:name]).to include('has already been taken')
    end
  end
end
