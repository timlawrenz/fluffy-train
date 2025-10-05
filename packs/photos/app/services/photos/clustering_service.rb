# frozen_string_literal: true

module Photos
  class ClusteringService
    DEFAULT_K_CLUSTERS = 5

    def initialize(k_clusters: DEFAULT_K_CLUSTERS)
      @k_clusters = k_clusters
    end

    def call
      photos_to_cluster = fetch_unclustered_photos

      return no_photos_result if photos_to_cluster.empty?

      perform_clustering_workflow(photos_to_cluster)
    rescue StandardError => e
      log_error(e)
      { success: false, error: e.message }
    end

    private

    attr_reader :k_clusters

    def fetch_unclustered_photos
      Photo.where(cluster_id: nil)
           .where.not(embedding: nil)
           .includes(:persona)
    end

    def build_embeddings_matrix(photos)
      embeddings = photos.map(&:embedding)
      # Convert array embeddings to Numo::DFloat matrix for Rumale
      matrix_data = embeddings.map(&:to_a)
      Numo::DFloat.cast(matrix_data)
    end

    def perform_clustering(embeddings_matrix, actual_k)
      kmeans = Rumale::Clustering::KMeans.new(n_clusters: actual_k, random_seed: 42)
      kmeans.fit_predict(embeddings_matrix)
    end

    def create_clusters(actual_k)
      (0...actual_k).map do |cluster_index|
        Cluster.create!(
          name: "Cluster #{cluster_index + 1}",
          status: 0 # active status
        )
      end
    end

    def assign_photos_to_clusters(photos, cluster_labels, clusters)
      photos.each_with_index do |photo, index|
        cluster_id = clusters[cluster_labels[index]]&.id
        photo.update!(cluster_id: cluster_id) if cluster_id
      end
    end

    def no_photos_result
      { success: true, message: 'No photos to cluster', photos_processed: 0 }
    end

    def perform_clustering_workflow(photos_to_cluster)
      embeddings_matrix = build_embeddings_matrix(photos_to_cluster)
      actual_k = [k_clusters, embeddings_matrix.shape[0]].min
      cluster_labels = perform_clustering(embeddings_matrix, actual_k)

      ActiveRecord::Base.transaction do
        clusters = create_clusters(actual_k)
        assign_photos_to_clusters(photos_to_cluster, cluster_labels, clusters)
      end

      success_result(photos_to_cluster.length, actual_k)
    end

    def success_result(photos_processed, actual_clusters_created)
      {
        success: true,
        message: "Successfully clustered #{photos_processed} photos into #{actual_clusters_created} clusters",
        photos_processed: photos_processed,
        clusters_created: actual_clusters_created
      }
    end

    def log_error(error)
      Rails.logger.error "Photos::ClusteringService failed: #{error.message}"
      Rails.logger.error error.backtrace.join("\n")
    end
  end
end
