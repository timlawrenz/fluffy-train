# frozen_string_literal: true

require 'spec_helper'
require 'gl_command/rspec'
require 'fileutils'
require 'base64'

RSpec.describe 'Photos::Import Integration', type: :integration do
  # Stub the Rails models and database behavior
  before do
    # Mock ApplicationRecord first
    stub_const('ApplicationRecord', Class.new)
    # Mock OllamaClient first to avoid loading issues
    stub_const('OllamaClient', Class.new do
      def self.get_sharpness_score(*)
        85.5
      end
      
      def self.get_exposure_score(*)
        0.75
      end
      
      def self.get_aesthetic_score(*)
        8
      end
      
      def self.detect_objects(*)
        [{ 'label' => 'cat', 'confidence' => 0.95 }]
      end
      
      Error = Class.new(StandardError)
    end)
    
    # Mock Persona class
    stub_const('Persona', Class.new(ApplicationRecord) do
      attr_accessor :id, :name
    end)
    
    # Mock Photo class with ActiveRecord-like behavior
    stub_const('Photo', Class.new do
      def self.find_or_initialize_by(attributes)
        existing = @records&.find { |r| r.path == attributes[:path] }
        return existing if existing
        
        new.tap do |photo|
          photo.path = attributes[:path]
          photo.instance_variable_set(:@new_record, true)
        end
      end
      
      def self.create!(attributes)
        @records ||= []
        @records << new.tap do |photo|
          attributes.each { |k, v| photo.send("#{k}=", v) }
          photo.instance_variable_set(:@new_record, false)
          photo.id = @records.length
        end
      end
      
      def self.where(conditions)
        @records ||= []
        @records.select do |record|
          conditions.all? { |key, value| record.send(key) == value }
        end
      end
      
      def self.count
        (@records ||= []).count
      end
      
      def self.last
        (@records ||= []).last
      end
      
      def new_record?
        @new_record == true
      end
      
      def persisted?
        !new_record?
      end
      
      def save
        @new_record = false
        Photo.instance_variable_get(:@records).push(self) unless Photo.instance_variable_get(:@records)&.include?(self)
        true
      end
      
      def destroy
        Photo.instance_variable_get(:@records)&.delete(self)
      end
      
      def errors
        @errors ||= double('Errors', full_messages: [])
      end
      
      def image
        @image ||= double('Image', attach: nil)
      end
      
      attr_accessor :id, :path, :persona, :photo_analysis
    end)
    
    # Mock PhotoAnalysis class with ActiveRecord-like behavior
    stub_const('PhotoAnalysis', Class.new do
      def self.create!(attributes)
        @records ||= []
        @records << new.tap do |analysis|
          attributes.each { |k, v| analysis.send("#{k}=", v) }
          analysis.id = @records.length
        end
      end
      
      def self.joins(association)
        self
      end
      
      def self.where(conditions)
        @records ||= []
        @records.select do |record|
          # Simple matching for the joins query
          if conditions.is_a?(Hash) && conditions[:photos]
            conditions[:photos].all? { |key, value| record.photo&.send(key) == value }
          else
            conditions.all? { |key, value| record.send(key) == value }
          end
        end
      end
      
      def self.count
        (@records ||= []).count
      end
      
      def self.last
        (@records ||= []).last
      end
      
      def destroy
        PhotoAnalysis.instance_variable_get(:@records)&.delete(self)
      end
      
      attr_accessor :id, :photo, :sharpness_score, :exposure_score, :aesthetic_score, :detected_objects
    end)
    
    # Mock Rails and ActiveRecord classes
    stub_const('Rails', Class.new do
      def self.logger
        @logger ||= double('Logger', error: nil)
      end
    end)
    
    stub_const('ActiveRecord', Module.new do
      const_set('RecordInvalid', Class.new(StandardError))
    end)
    
    # Mock GenerateEmbeddingJob
    stub_const('GenerateEmbeddingJob', Class.new do
      def self.perform_later(photo_id)
        # Do nothing for testing
      end
    end)
    
    # Reset records before each test
    Photo.instance_variable_set(:@records, [])
    PhotoAnalysis.instance_variable_set(:@records, [])
    
    # Now require the commands after mocking dependencies
    require_relative '../../app/commands/photos/import'
  end

  let(:persona) { Persona.new.tap { |p| p.id = 1; p.instance_variable_set(:@attributes, { id: 1, name: 'Test Persona' }) } }
  let(:temp_dir) { '/tmp/fluffy_train_integration_test' }
  let(:test_image_path) { File.join(temp_dir, 'test_image.jpg') }

  around do |example|
    FileUtils.mkdir_p(temp_dir)
    create_test_image
    example.run
    FileUtils.rm_rf(temp_dir)
  end

  describe 'successful import workflow' do
    before do
      # Mock the external API calls to return predictable data
      allow(OllamaClient).to receive(:get_sharpness_score).and_return(85.5)
      allow(OllamaClient).to receive(:get_exposure_score).and_return(0.75)
      allow(OllamaClient).to receive(:get_aesthetic_score).and_return(8)
      allow(OllamaClient).to receive(:detect_objects).and_return([
        { 'label' => 'cat', 'confidence' => 0.95 },
        { 'label' => 'tree', 'confidence' => 0.80 }
      ])
    end

    it 'successfully imports a photo and creates analysis (AC1, AC2, AC3, AC4, AC6)' do
      expect {
        result = Photos::Import.call(path: test_image_path, persona: persona)
        expect(result).to be_success
      }.to change(Photo, :count).by(1)
        .and change(PhotoAnalysis, :count).by(1)

      photo = Photo.last
      photo_analysis = PhotoAnalysis.last

      # AC1: PhotoAnalysis record is created and associated with Photo
      expect(photo_analysis.photo).to eq(photo)
      expect(photo.photo_analysis).to eq(photo_analysis)

      # AC2: Sharpness and exposure scores are populated with valid floating-point numbers
      expect(photo_analysis.sharpness_score).to be_a(Float)
      expect(photo_analysis.sharpness_score).to eq(85.5)
      expect(photo_analysis.exposure_score).to be_a(Float)
      expect(photo_analysis.exposure_score).to eq(0.75)

      # AC3: Aesthetic score is populated with valid number within 1-10 range
      expect(photo_analysis.aesthetic_score).to be_a(Numeric)
      expect(photo_analysis.aesthetic_score).to eq(8)
      expect(photo_analysis.aesthetic_score).to be_between(1, 10)

      # AC4: Detected objects contains valid JSON array with required keys
      expect(photo_analysis.detected_objects).to be_an(Array)
      expect(photo_analysis.detected_objects).to all(
        include('label' => be_a(String), 'confidence' => be_a(Numeric))
      )
      expect(photo_analysis.detected_objects.first['label']).to eq('cat')
      expect(photo_analysis.detected_objects.first['confidence']).to eq(0.95)

      # AC6: Process triggered with local file path
      expect(photo.path).to eq(test_image_path)
      expect(photo.persona).to eq(persona)
    end

    it 'creates photo analysis with all expected fields populated' do
      result = Photos::Import.call(path: test_image_path, persona: persona)
      
      expect(result).to be_success
      expect(result.photo).to be_a(Photo)
      expect(result.photo_analysis).to be_a(PhotoAnalysis)
      
      photo_analysis = result.photo_analysis
      expect(photo_analysis.sharpness_score).to eq(85.5)
      expect(photo_analysis.exposure_score).to eq(0.75)
      expect(photo_analysis.aesthetic_score).to eq(8)
      expect(photo_analysis.detected_objects).to eq([
        { 'label' => 'cat', 'confidence' => 0.95 },
        { 'label' => 'tree', 'confidence' => 0.80 }
      ])
    end
  end

  describe 'failure scenarios with rollback (AC5)' do
    it 'rolls back entire transaction when sharpness analysis fails' do
      allow(OllamaClient).to receive(:get_sharpness_score)
        .and_raise(OllamaClient::Error, 'API connection failed')

      expect {
        result = Photos::Import.call(path: test_image_path, persona: persona)
        expect(result).to be_failure
        expect(result.full_error_message).to include('Failed to get sharpness score')
      }.not_to change { [Photo.count, PhotoAnalysis.count] }

      # Verify no records were left in database
      expect(Photo.where(path: test_image_path)).to be_empty
      expect(PhotoAnalysis.joins(:photo).where(photos: { path: test_image_path })).to be_empty
    end

    it 'rolls back entire transaction when exposure analysis fails' do
      allow(OllamaClient).to receive(:get_sharpness_score).and_return(85.5)
      allow(OllamaClient).to receive(:get_exposure_score)
        .and_raise(OllamaClient::Error, 'Exposure analysis failed')

      expect {
        result = Photos::Import.call(path: test_image_path, persona: persona)
        expect(result).to be_failure
        expect(result.full_error_message).to include('Failed to get exposure score')
      }.not_to change { [Photo.count, PhotoAnalysis.count] }

      # Verify no records were left in database
      expect(Photo.where(path: test_image_path)).to be_empty
      expect(PhotoAnalysis.joins(:photo).where(photos: { path: test_image_path })).to be_empty
    end

    it 'rolls back entire transaction when aesthetic analysis fails' do
      allow(OllamaClient).to receive(:get_sharpness_score).and_return(85.5)
      allow(OllamaClient).to receive(:get_exposure_score).and_return(0.75)
      allow(OllamaClient).to receive(:get_aesthetic_score)
        .and_raise(OllamaClient::Error, 'Aesthetic analysis failed')

      expect {
        result = Photos::Import.call(path: test_image_path, persona: persona)
        expect(result).to be_failure
        expect(result.full_error_message).to include('Failed to get aesthetic score')
      }.not_to change { [Photo.count, PhotoAnalysis.count] }

      # Verify no records were left in database
      expect(Photo.where(path: test_image_path)).to be_empty
      expect(PhotoAnalysis.joins(:photo).where(photos: { path: test_image_path })).to be_empty
    end

    it 'rolls back entire transaction when object detection fails' do
      allow(OllamaClient).to receive(:get_sharpness_score).and_return(85.5)
      allow(OllamaClient).to receive(:get_exposure_score).and_return(0.75)
      allow(OllamaClient).to receive(:get_aesthetic_score).and_return(8)
      allow(OllamaClient).to receive(:detect_objects)
        .and_raise(OllamaClient::Error, 'Object detection failed')

      expect {
        result = Photos::Import.call(path: test_image_path, persona: persona)
        expect(result).to be_failure
        expect(result.full_error_message).to include('Failed to detect objects')
      }.not_to change { [Photo.count, PhotoAnalysis.count] }

      # Verify no records were left in database
      expect(Photo.where(path: test_image_path)).to be_empty
      expect(PhotoAnalysis.joins(:photo).where(photos: { path: test_image_path })).to be_empty
    end

    it 'rolls back entire transaction when photo analysis save fails' do
      allow(OllamaClient).to receive(:get_sharpness_score).and_return(85.5)
      allow(OllamaClient).to receive(:get_exposure_score).and_return(0.75)
      allow(OllamaClient).to receive(:get_aesthetic_score).and_return(8)
      allow(OllamaClient).to receive(:detect_objects).and_return([
        { 'label' => 'cat', 'confidence' => 0.95 }
      ])

      # Mock PhotoAnalysis.create! to fail
      allow(PhotoAnalysis).to receive(:create!)
        .and_raise(ActiveRecord::RecordInvalid, 'Validation failed')

      expect {
        result = Photos::Import.call(path: test_image_path, persona: persona)
        expect(result).to be_failure
        expect(result.full_error_message).to include('Failed to save photo analysis')
      }.not_to change { [Photo.count, PhotoAnalysis.count] }

      # Verify no records were left in database
      expect(Photo.where(path: test_image_path)).to be_empty
      expect(PhotoAnalysis.joins(:photo).where(photos: { path: test_image_path })).to be_empty
    end
  end

  describe 'edge cases' do
    it 'handles non-existent file path gracefully' do
      non_existent_path = '/path/to/non_existent_file.jpg'

      expect {
        result = Photos::Import.call(path: non_existent_path, persona: persona)
        expect(result).to be_failure
        expect(result.full_error_message).to include('Photo file not found')
      }.not_to change { [Photo.count, PhotoAnalysis.count] }
    end

    it 'handles duplicate photo import gracefully' do
      # Mock successful analysis for both attempts
      allow(OllamaClient).to receive(:get_sharpness_score).and_return(85.5)
      allow(OllamaClient).to receive(:get_exposure_score).and_return(0.75)
      allow(OllamaClient).to receive(:get_aesthetic_score).and_return(8)
      allow(OllamaClient).to receive(:detect_objects).and_return([
        { 'label' => 'cat', 'confidence' => 0.95 }
      ])

      # First import
      result1 = Photos::Import.call(path: test_image_path, persona: persona)
      expect(result1).to be_success

      # Second import of same path should not create duplicate
      expect {
        result2 = Photos::Import.call(path: test_image_path, persona: persona)
        expect(result2).to be_success
        expect(result2.photo).to eq(result1.photo)
      }.not_to change { [Photo.count, PhotoAnalysis.count] }
    end
  end

  private

  def create_test_image
    # Create a minimal JPEG file for testing
    File.write(test_image_path, Base64.decode64(minimal_jpeg_base64))
  end

  # Minimal valid JPEG file in base64 format (1x1 pixel red square)
  def minimal_jpeg_base64
    '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB' \
    'AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEB' \
    'AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIA' \
    'AhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QA' \
    'FQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCn' \
    'AA8='
  end
end