# frozen_string_literal: true

require 'spec_helper'
require 'gl_command'

RSpec.describe 'Photos::Import' do
  it 'command file exists and is syntactically valid' do
    command_file = File.expand_path('../../../app/commands/photos/import.rb', __dir__)
    expect(File.exist?(command_file)).to be true

    # Check if the file can be parsed as valid Ruby
    expect { File.read(command_file) }.not_to raise_error

    # Basic syntax check
    ruby_code = File.read(command_file)
    expect(ruby_code).to include('class Import < GLCommand::Chainable')
    expect(ruby_code).to include('requires :path, persona: Persona')
    expect(ruby_code).to include('returns :photo, :photo_analysis')
    expect(ruby_code).to include('chain CreatePhoto')
    expect(ruby_code).to include('Photos::AnalysePhoto')
  end
end
