# frozen_string_literal: true

require 'spec_helper'
require 'gl_command/rspec'

RSpec.describe 'Photos::Import Integration', type: :integration do
  before do
    # Mock all the dependencies we need
    stub_const('ApplicationRecord', Class.new)
    
    stub_const('Persona', Class.new(ApplicationRecord) do
      attr_accessor :id, :name
    end)
    
    stub_const('Photo', Class.new(ApplicationRecord) do
      attr_accessor :id, :path, :persona, :photo_analysis
      
      def self.find_or_initialize_by(attributes)
        new.tap do |photo|
          photo.path = attributes[:path]
          photo.instance_variable_set(:@new_record, true)
        end
      end
      
      def new_record?; @new_record == true; end
      def persisted?; !new_record?; end
      def save; @new_record = false; true; end
      def destroy; end
      def errors; OpenStruct.new(full_messages: []); end
      def image; OpenStruct.new(attach: nil); end
    end)
    
    stub_const('PhotoAnalysis', Class.new(ApplicationRecord) do
      attr_accessor :id, :photo, :sharpness_score, :exposure_score, :aesthetic_score, :detected_objects
      
      def self.create!(attributes)
        new.tap do |analysis|
          attributes.each { |k, v| analysis.send("#{k}=", v) }
          analysis.id = 1
        end
      end
      
      def destroy; end
    end)
    
    stub_const('Rails', Class.new do
      def self.logger; OpenStruct.new(error: nil); end
    end)
    
    stub_const('ActiveRecord', Module.new)
    ActiveRecord.const_set('RecordInvalid', Class.new(StandardError))
    
    stub_const('GenerateEmbeddingJob', Class.new do
      def self.perform_later(photo_id); end
    end)
    
    # Mock OllamaClient with Error constant
    ollama_mock = Class.new do
      def self.get_sharpness_score(*); 85.5; end
      def self.get_exposure_score(*); 0.75; end
      def self.get_aesthetic_score(*); 8; end
      def self.detect_objects(*); [{ 'label' => 'cat', 'confidence' => 0.95 }]; end
    end
    ollama_mock.const_set('Error', Class.new(StandardError))
    stub_const('OllamaClient', ollama_mock)
    
    # Mock File operations
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:open).and_yield(double('File'))
    allow(File).to receive(:basename).and_return('test.jpg')
    
    # Load the command after mocking dependencies
    load File.expand_path('../../app/commands/photos/import.rb', __dir__)
  end

  let(:persona) do
    Persona.new.tap do |p|
      p.id = 1
      p.name = 'Test Persona'
    end
  end
  
  let(:test_image_path) { '/tmp/test_image.jpg' }

  describe 'successful import workflow (AC1, AC2, AC3, AC4, AC6)' do
    it 'successfully imports a photo and creates analysis with all expected fields' do
      result = Photos::Import.call(path: test_image_path, persona: persona)
      
      expect(result).to be_success
      expect(result.photo).to be_a(Photo)
      expect(result.photo_analysis).to be_a(PhotoAnalysis)
      
      # AC1: PhotoAnalysis record is created and associated with Photo
      expect(result.photo_analysis.photo).to eq(result.photo)
      
      # AC2: Sharpness and exposure scores are populated with valid floating-point numbers
      expect(result.photo_analysis.sharpness_score).to be_a(Float)
      expect(result.photo_analysis.sharpness_score).to eq(85.5)
      expect(result.photo_analysis.exposure_score).to be_a(Float)
      expect(result.photo_analysis.exposure_score).to eq(0.75)
      
      # AC3: Aesthetic score is populated with valid number within 1-10 range
      expect(result.photo_analysis.aesthetic_score).to be_a(Numeric)
      expect(result.photo_analysis.aesthetic_score).to eq(8)
      expect(result.photo_analysis.aesthetic_score).to be_between(1, 10)
      
      # AC4: Detected objects contains valid JSON array with required keys
      expect(result.photo_analysis.detected_objects).to be_an(Array)
      expect(result.photo_analysis.detected_objects).to all(
        include('label' => be_a(String), 'confidence' => be_a(Numeric))
      )
      
      # AC6: Process triggered with local file path
      expect(result.photo.path).to eq(test_image_path)
      expect(result.photo.persona).to eq(persona)
    end
  end

  describe 'failure scenarios with rollback (AC5)' do
    it 'fails when sharpness analysis raises OllamaClient::Error' do
      allow(OllamaClient).to receive(:get_sharpness_score)
        .and_raise(OllamaClient::Error, 'API connection failed')

      result = Photos::Import.call(path: test_image_path, persona: persona)
      
      expect(result).to be_failure
      expect(result.full_error_message).to include('Failed to get sharpness score')
      expect(result.full_error_message).to include('API connection failed')
    end

    it 'fails when photo analysis save raises ActiveRecord::RecordInvalid' do
      allow(PhotoAnalysis).to receive(:create!)
        .and_raise(ActiveRecord::RecordInvalid, 'Validation failed: aesthetic_score is required')

      result = Photos::Import.call(path: test_image_path, persona: persona)
      
      expect(result).to be_failure
      expect(result.full_error_message).to include('Failed to save photo analysis')
      expect(result.full_error_message).to include('Validation failed')
    end
  end

  describe 'edge cases' do
    it 'fails gracefully when photo file does not exist' do
      allow(File).to receive(:exist?).with(test_image_path).and_return(false)
      
      result = Photos::Import.call(path: test_image_path, persona: persona)
      
      expect(result).to be_failure
      expect(result.full_error_message).to include('Photo file not found at path')
    end
  end
  
  describe 'command interface' do
    it 'has the expected GLCommand interface' do
      expect(Photos::Import).to respond_to(:call)
      expect(Photos::Import).to be < GLCommand::Chainable
    end
  end
end