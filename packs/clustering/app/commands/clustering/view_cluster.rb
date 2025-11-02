# frozen_string_literal: true

module Clustering
  class ViewCluster < GLCommand::Callable
    include ActiveModel::Validations

    validates :cluster_id, presence: true

    requires :cluster_id
    allows :sample_size
    returns :output_path, :message

    def call
      return unless valid?

      cluster = find_cluster
      return if cluster.nil?

      size = sample_size || 10
      sample_photos = cluster.photos.limit(size).order('RANDOM()')
      output_dir = create_output_directory(cluster)
      copy_sample_images(sample_photos, output_dir)

      context.output_path = output_dir
      context.message = "Exported #{sample_photos.count} sample images to #{output_dir}"
    end

    private

    def find_cluster
      cluster = Clustering::Cluster.find_by(id: cluster_id)
      if cluster.nil?
        stop_and_fail!('Cluster not found')
        return nil
      end
      cluster
    end

    def create_output_directory(cluster)
      output_dir = "/tmp/cluster_samples/cluster_#{cluster.id}"
      FileUtils.mkdir_p(output_dir)
      output_dir
    end

    def copy_sample_images(photos, output_dir)
      photos.each do |photo|
        next unless File.exist?(photo.path)

        filename = File.basename(photo.path)
        destination = File.join(output_dir, filename)
        FileUtils.cp(photo.path, destination)
      end
    end
  end
end
