# frozen_string_literal: true

module Clustering
  class ListClusters < GLCommand::Callable
    returns :message

    def call
      clusters = Clustering::Cluster.order(:id).to_a

      if clusters.empty?
        puts 'No clusters found'
        context.message = 'No clusters found'
      else
        print_clusters_table(clusters)
        context.message = "Listed #{clusters.count} clusters"
      end
    end

    private

    def print_clusters_table(clusters)
      puts format('%-5s | %-30s | %-10s', 'ID', 'Name', 'Photos')
      puts '-' * 50

      clusters.each do |cluster|
        puts format('%-5s | %-30s | %-10s', cluster.id, cluster.name || '(unnamed)', cluster.photos_count)
      end
    end
  end
end
