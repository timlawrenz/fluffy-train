# frozen_string_literal: true

require 'spec_helper'

# Mock Rails environment for the Rake task testing
ENV['RAILS_ENV'] = 'test'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'scheduling:post_next_best Rake Task Integration', type: :integration do
  # This integration test verifies the Rake task behavior by testing the interface
  # and expected outcomes without requiring full database setup

  describe 'rake task interface validation' do
    it 'exists and has the expected structure' do
      # Test that the task file exists and can be loaded
      rake_file = File.expand_path('../../lib/tasks/scheduling.rake', __dir__)
      expect(File.exist?(rake_file)).to be true

      # Verify the task file contains expected structure
      rake_content = File.read(rake_file)
      expect(rake_content).to include('namespace :scheduling')
      expect(rake_content).to include('task :post_next_best')
      expect(rake_content).to include('Scheduling::Strategies::CuratorsChoice.call')
    end

    it 'includes expected behavior patterns' do
      # Load task file without executing to test interface
      rake_content = File.read(File.expand_path('../../lib/tasks/scheduling.rake', __dir__))

      # Verify the task includes persona validation
      expect(rake_content).to include('Personas.find_by_name')
      expect(rake_content).to include('Personas.list.first')

      # Verify error handling
      expect(rake_content).to include('exit 1')
      expect(rake_content).to include('Error:')
    end
  end

  describe 'task behavior simulation' do
    # Test the task behavior using stubs and mocks to avoid database dependencies
    before do
      # Mock ActiveSupport's present? method for strings and nil
      class String
        def present?
          !empty?
        end
      end

      class NilClass
        def present?
          false
        end
      end

      # Set up minimal stubs for required classes
      stub_const('ApplicationRecord', Class.new)
      stub_const('Persona', Class.new(ApplicationRecord) do
        attr_accessor :name, :id

        def initialize(name: 'test', id: 1)
          @name = name
          @id = id
        end
      end)

      stub_const('Scheduling::Post', Class.new(ApplicationRecord))
      stub_const('Photo', Class.new(ApplicationRecord) do
        attr_accessor :id

        def initialize(id: 1)
          @id = id
        end
      end)

      # Mock the GLCommand result
      stub_const('GLCommand::Result', Class.new do
        attr_accessor :success, :selected_photo, :errors

        def initialize(success: true, selected_photo: nil, errors: [])
          @success = success
          @selected_photo = selected_photo
          @errors = errors
        end

        def success?
          @success
        end
      end)

      # Mock Personas module
      personas_module = Module.new do
        def self.find_by_name(name:)
          return unless name == 'existing_persona'

          Persona.new(name: name)
        end

        def self.list
          [Persona.new(name: 'first_persona')]
        end
      end
      stub_const('Personas', personas_module)

      curators_choice_class = Class.new do
        def self.call(persona:)
          GLCommand::Result.new(success: true, selected_photo: Photo.new)
        end
      end
      stub_const('Scheduling::Strategies::CuratorsChoice', curators_choice_class)

      # Load Rake application with mocked environment task
      require 'rake'
      Rake.application.clear

      # Define a mock environment task
      Rake::Task.define_task(:environment)

      # Load the scheduling task
      load File.expand_path('../../lib/tasks/scheduling.rake', __dir__)
    end

    context 'with valid persona name argument' do
      it 'calls CuratorsChoice with the found persona' do
        expect(Scheduling::Strategies::CuratorsChoice).to receive(:call) do |args|
          expect(args[:persona].name).to eq('existing_persona')
          GLCommand::Result.new(success: true, selected_photo: Photo.new)
        end

        capture_stdout_and_exit_status do
          Rake::Task['scheduling:post_next_best'].invoke('existing_persona')
        end

        # Clear for next test
        Rake::Task['scheduling:post_next_best'].reenable
      end

      it 'handles successful photo selection' do
        selected_photo = Photo.new(id: 123)
        allow(Scheduling::Strategies::CuratorsChoice).to receive(:call)
          .and_return(GLCommand::Result.new(success: true, selected_photo: selected_photo))

        output, status = capture_stdout_and_exit_status do
          Rake::Task['scheduling:post_next_best'].invoke('existing_persona')
        end

        expect(output).to include("Successfully selected and posted photo: #{selected_photo.id}")
        expect(status).to be_nil # No exit called

        Rake::Task['scheduling:post_next_best'].reenable
      end

      it 'handles no available photos scenario' do
        allow(Scheduling::Strategies::CuratorsChoice).to receive(:call)
          .and_return(GLCommand::Result.new(success: true, selected_photo: nil))

        output, status = capture_stdout_and_exit_status do
          Rake::Task['scheduling:post_next_best'].invoke('existing_persona')
        end

        expect(output).to include('No unposted photos available for persona: existing_persona')
        expect(status).to be_nil # No exit called

        Rake::Task['scheduling:post_next_best'].reenable
      end
    end

    context 'with nonexistent persona name' do
      it 'exits with error when persona is not found' do
        output, status = capture_stdout_and_exit_status do
          Rake::Task['scheduling:post_next_best'].invoke('nonexistent_persona')
        end

        expect(output).to include("Error: Persona with name 'nonexistent_persona' not found.")
        expect(status).to eq(1)

        Rake::Task['scheduling:post_next_best'].reenable
      end
    end

    context 'without persona name argument' do
      context 'when personas exist' do
        it 'uses the first available persona' do
          expect(Personas).to receive(:list).and_return([Persona.new(name: 'first_persona')])
          expect(Scheduling::Strategies::CuratorsChoice).to receive(:call) do |args|
            expect(args[:persona].name).to eq('first_persona')
            GLCommand::Result.new(success: true, selected_photo: nil)
          end

          capture_stdout_and_exit_status do
            Rake::Task['scheduling:post_next_best'].invoke
          end

          Rake::Task['scheduling:post_next_best'].reenable
        end
      end

      context 'when no personas exist' do
        it 'exits with error when no personas found' do
          allow(Personas).to receive(:list).and_return([])

          output, status = capture_stdout_and_exit_status do
            Rake::Task['scheduling:post_next_best'].invoke
          end

          expect(output).to include('Error: No personas found. Please create a persona first.')
          expect(status).to eq(1)

          Rake::Task['scheduling:post_next_best'].reenable
        end
      end
    end

    context 'when CuratorsChoice service fails' do
      it 'exits with error and displays error messages' do
        allow(Scheduling::Strategies::CuratorsChoice).to receive(:call)
          .and_return(GLCommand::Result.new(success: false, errors: ['Service error', 'API failure']))

        output, status = capture_stdout_and_exit_status do
          Rake::Task['scheduling:post_next_best'].invoke('existing_persona')
        end

        expect(output).to include('Failed to post photo: Service error, API failure')
        expect(status).to eq(1)

        Rake::Task['scheduling:post_next_best'].reenable
      end
    end
  end

  describe 'integration with core services' do
    before do
      # Mock ActiveSupport's present? method for strings and nil
      class String
        def present?
          !empty?
        end
      end

      class NilClass
        def present?
          false
        end
      end

      # Mock the essential components
      stub_const('Persona', Class.new do
        attr_accessor :name

        def initialize(name:)
          @name = name
        end
      end)

      personas_module = Module.new do
        def self.find_by_name(name:)
          return unless %w[test_persona service_test_persona].include?(name)

          Persona.new(name: name)
        end

        def self.list
          [Persona.new(name: 'default_persona')]
        end
      end
      stub_const('Personas', personas_module)

      stub_const('Scheduling::Strategies::CuratorsChoice', Class.new do
        def self.call(persona:)
          GLCommand::Result.new(success: true, selected_photo: Photo.new)
        end
      end)
      stub_const('GLCommand::Result', Class.new)

      require 'rake'
      Rake.application.clear

      # Define a mock environment task
      Rake::Task.define_task(:environment)

      # Load the scheduling task
      load File.expand_path('../../lib/tasks/scheduling.rake', __dir__)
    end

    it 'integrates with Personas.find_by_name when persona name is provided' do
      test_persona = Persona.new(name: 'test_persona')
      expect(Personas).to receive(:find_by_name).with(name: 'test_persona').and_return(test_persona)

      allow(Scheduling::Strategies::CuratorsChoice).to receive(:call)
        .and_return(double(success?: true, selected_photo: nil))

      capture_stdout_and_exit_status do
        Rake::Task['scheduling:post_next_best'].invoke('test_persona')
      end

      Rake::Task['scheduling:post_next_best'].reenable
    end

    it 'integrates with Personas.list when no persona name is provided' do
      test_persona = Persona.new(name: 'default_persona')
      expect(Personas).to receive(:list).and_return([test_persona])

      allow(Scheduling::Strategies::CuratorsChoice).to receive(:call)
        .and_return(double(success?: true, selected_photo: nil))

      capture_stdout_and_exit_status do
        Rake::Task['scheduling:post_next_best'].invoke
      end

      Rake::Task['scheduling:post_next_best'].reenable
    end

    it 'calls CuratorsChoice service with the correct persona parameter' do
      test_persona = Persona.new(name: 'service_test_persona')
      allow(Personas).to receive(:find_by_name).and_return(test_persona)

      expect(Scheduling::Strategies::CuratorsChoice).to receive(:call)
        .with(persona: test_persona)
        .and_return(double(success?: true, selected_photo: nil))

      capture_stdout_and_exit_status do
        Rake::Task['scheduling:post_next_best'].invoke('service_test_persona')
      end

      Rake::Task['scheduling:post_next_best'].reenable
    end
  end

  # Helper method to capture stdout and exit status
  # rubocop:disable Metrics/MethodLength
  def capture_stdout_and_exit_status
    original_stdout = $stdout
    $stdout = StringIO.new
    status = nil

    begin
      yield
    rescue SystemExit => e
      status = e.status
    ensure
      output = $stdout.string
      $stdout = original_stdout
    end

    [output, status]
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable RSpec/DescribeClass
