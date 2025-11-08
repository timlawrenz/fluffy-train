# frozen_string_literal: true

module Clustering
  class ListClusters < GLCommand::Callable
    allows persona_id: Integer
    returns :message

    def call
      clusters = if persona_id
                   Clustering::Cluster.for_persona(persona_id).order(:id).to_a
                 else
                   Clustering::Cluster.order(:id).includes(:persona).to_a
                 end

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
      puts format('%-5s | %-20s | %-30s | %-10s', 'ID', 'Persona', 'Name', 'Photos')
      puts '-' * 70

      clusters.each do |cluster|
        puts format('%-5s | %-20s | %-30s | %-10s', 
                    cluster.id, 
                    cluster.persona&.name || '(none)',
                    cluster.name || '(unnamed)', 
                    cluster.photos_count)
      end
    end
  end
end
