# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'spec_helper'
require 'gl_command'
require 'gl_command/rspec'
require 'vips'

# Mock Photo class for testing

require_relative '../../../../app/commands/photos/analyse/sharpness'

RSpec.describe Photos::Analyse::Sharpness, type: :command do
  before do
    stub_const('Photo', Class.new)
  end

  let(:temp_dir) { '/tmp/fluffy_train_test_images' }
  let(:sharp_image_path) { File.join(temp_dir, 'sharp_test_image.jpg') }
  let(:blurry_image_path) { File.join(temp_dir, 'blurry_test_image.jpg') }
  let(:photo_sharp) { double('Photo', path: sharp_image_path) }
  let(:photo_blurry) { double('Photo', path: blurry_image_path) }

  around do |example|
    FileUtils.mkdir_p(temp_dir)
    create_test_images
    example.run
    FileUtils.rm_rf(temp_dir)
  end

  describe 'interface' do
    it { is_expected.to require(:photo) }
    it { is_expected.to returns(:sharpness_score) }
  end

  describe '#call' do
    context 'with a valid image file' do
      it 'is successful' do
        result = described_class.call(photo: photo_sharp)
        expect(result).to be_success
      end

      it 'returns a numeric sharpness score' do
        result = described_class.call(photo: photo_sharp)
        expect(result.sharpness_score).to be_a(Float)
        expect(result.sharpness_score).to be >= 0
      end

      it 'calculates higher scores for sharper images' do
        sharp_result = described_class.call(photo: photo_sharp)
        blurry_result = described_class.call(photo: photo_blurry)

        expect(sharp_result.sharpness_score).to be > blurry_result.sharpness_score
      end
    end

    context 'when photo file does not exist' do
      let(:non_existent_photo) { double('Photo', path: '/path/to/non_existent_file.jpg') }

      it 'is a failure' do
        result = described_class.call(photo: non_existent_photo)
        expect(result).to be_failure
      end

      it 'returns an appropriate error message' do
        result = described_class.call(photo: non_existent_photo)
        expect(result.full_error_message).to eq('Photo file not found at path: /path/to/non_existent_file.jpg')
      end
    end

    context 'when file exists but is not a valid image' do
      let(:invalid_image_path) { File.join(temp_dir, 'invalid_image.txt') }
      let(:photo_invalid) { double('Photo', path: invalid_image_path) }

      before do
        File.write(invalid_image_path, 'This is not an image file')
      end

      it 'is a failure' do
        result = described_class.call(photo: photo_invalid)
        expect(result).to be_failure
      end

      it 'returns an error message about image processing failure' do
        result = described_class.call(photo: photo_invalid)
        expect(result.full_error_message).to match(/Failed to analyze image sharpness/)
      end
    end
  end

  private

  def create_test_images
    # Create a sharp test image (high frequency content)
    sharp_image = create_sharp_pattern
    sharp_image.write_to_file(sharp_image_path)

    # Create a blurry test image (same pattern but blurred)
    blurry_image = sharp_image.gaussblur(5.0) # Apply Gaussian blur
    blurry_image.write_to_file(blurry_image_path)
  end

  def create_sharp_pattern
    sharp_image = Vips::Image.black(100, 100)
    # Add high frequency pattern (checkerboard)
    (0...100).step(10) do |x|
      (0...100).step(10) do |y|
        sharp_image = sharp_image.draw_rect(255, x, y, 10, 10) if ((x / 10) + (y / 10)).even?
      end
    end
    sharp_image
  end
end
# rubocop:enable RSpec/VerifiedDoubles
