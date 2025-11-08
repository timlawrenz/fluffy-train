# frozen_string_literal: true

namespace :clustering do
  desc 'Generate clusters for photos using K-Means clustering on DINO embeddings'
  task generate: :environment do
    puts 'Starting photo clustering process...'

    begin
      personas = Persona.all
      
      if personas.empty?
        puts 'No personas found'
        next
      end

      personas.each do |persona|
        puts "\nClustering photos for persona: #{persona.name}..."
        
        clustering_service = Clustering::ClusteringService.new(persona: persona)
        result = clustering_service.call

        if result[:success]
          puts result[:message]
          if result[:photos_processed]&.positive?
            puts "Photos processed: #{result[:photos_processed]}"
            puts "Clusters created: #{result[:clusters_created]}" if result[:clusters_created]
          end
        else
          puts "Error for #{persona.name}: #{result[:error]}"
        end
      end
    rescue StandardError => e
      puts "Error: Failed to run clustering service: #{e.message}"
      exit 1
    end
  end
end
