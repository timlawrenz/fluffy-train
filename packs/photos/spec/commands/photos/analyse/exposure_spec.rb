# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles

require 'spec_helper'
require 'gl_command'
require 'gl_command/rspec'
require 'vips'

# Mock Photo class for testing

require_relative '../../../../app/commands/photos/analyse/exposure'

RSpec.describe Photos::Analyse::Exposure, type: :command do
  before do
    stub_const('Photo', Class.new)
  end

  let(:temp_dir) { '/tmp/fluffy_train_test_images' }
  let(:bright_image_path) { File.join(temp_dir, 'bright_test_image.jpg') }
  let(:dark_image_path) { File.join(temp_dir, 'dark_test_image.jpg') }
  let(:photo_bright) { double('Photo', path: bright_image_path) }
  let(:photo_dark) { double('Photo', path: dark_image_path) }

  around do |example|
    FileUtils.mkdir_p(temp_dir)
    create_test_images
    example.run
    FileUtils.rm_rf(temp_dir)
  end

  describe 'interface' do
    it { is_expected.to require(:photo) }
    it { is_expected.to returns(:exposure_score) }
  end

  describe '#call' do
    context 'with a valid image file' do
      it 'is successful' do
        result = described_class.call(photo: photo_bright)
        expect(result).to be_success
      end

      it 'returns a numeric exposure score' do
        result = described_class.call(photo: photo_bright)
        expect(result.exposure_score).to be_a(Float)
        expect(result.exposure_score).to be >= 0.0
        expect(result.exposure_score).to be <= 1.0
      end

      it 'calculates higher scores for brighter images' do
        bright_result = described_class.call(photo: photo_bright)
        dark_result = described_class.call(photo: photo_dark)

        expect(bright_result.exposure_score).to be > dark_result.exposure_score
      end

      it 'returns normalized values between 0 and 1' do
        bright_result = described_class.call(photo: photo_bright)
        dark_result = described_class.call(photo: photo_dark)

        expect(bright_result.exposure_score).to be_between(0.0, 1.0).inclusive
        expect(dark_result.exposure_score).to be_between(0.0, 1.0).inclusive
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
        expect(result.full_error_message).to match(/Failed to analyze image exposure/)
      end
    end
  end

  private

  def create_test_images
    # Create a bright test image (high brightness values)
    bright_image = create_bright_image
    bright_image.write_to_file(bright_image_path)

    # Create a dark test image (low brightness values)
    dark_image = create_dark_image
    dark_image.write_to_file(dark_image_path)
  end

  def create_bright_image
    # Create an image with high brightness (closer to white)
    Vips::Image.new_from_array([[200, 220, 200], [220, 240, 220], [200, 220, 200]])
               .resize(50, vscale: 50, kernel: :nearest)
  end

  def create_dark_image
    # Create an image with low brightness (closer to black)
    Vips::Image.new_from_array([[30, 50, 30], [50, 70, 50], [30, 50, 30]])
               .resize(50, vscale: 50, kernel: :nearest)
  end
end
# rubocop:enable RSpec/VerifiedDoubles
