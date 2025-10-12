# frozen_string_literal: true

require 'gl_command'

module Clustering
  class ViewCluster < GLCommand::Callable
    requires :cluster_id
    allows :sample_size
    returns :output_path

    def call
      validate_inputs
      fetch_cluster
      sample_photos
      create_output_directory
      copy_image_files

      context.output_path = @output_path
    end

    private

    def validate_inputs
      stop_and_fail!('cluster_id is required') if cluster_id.nil?
      stop_and_fail!('cluster_id must be an integer') unless cluster_id.is_a?(Integer)

      stop_and_fail!('sample_size must be an integer') if sample_size && !sample_size.is_a?(Integer)

      return unless sample_size && sample_size <= 0

      stop_and_fail!('sample_size must be positive')
    end

    def fetch_cluster
      @cluster = Clustering::Cluster.find_by(id: cluster_id)
      stop_and_fail!("Cluster with ID #{cluster_id} not found") unless @cluster
    end

    def sample_photos
      @sample_size = sample_size || 10
      @photos = @cluster.photos.where.not(path: nil).limit(1000).to_a.sample(@sample_size)

      return unless @photos.empty?

      stop_and_fail!("No photos found in cluster #{cluster_id}")
    end

    def create_output_directory
      @output_path = "/tmp/cluster_samples/cluster_#{cluster_id}"
      FileUtils.mkdir_p(@output_path)
    end

    def copy_image_files
      @photos.each_with_index do |photo, index|
        next unless File.exist?(photo.path)

        file_extension = File.extname(photo.path)
        destination_filename = "#{index + 1}_#{File.basename(photo.path, file_extension)}#{file_extension}"
        destination_path = File.join(@output_path, destination_filename)

        FileUtils.cp(photo.path, destination_path)
      end
    end
  end
end
