# frozen_string_literal: true

namespace :clustering do
  desc 'Auto-name clusters based on detected objects'
  task :auto_name_clusters, [:persona_name] => :environment do |_, args|
    persona = if args[:persona_name].present?
                Personas.find_by_name(name: args[:persona_name])
              else
                Personas.list.first
              end

    unless persona
      puts 'Error: Persona not found'
      exit 1
    end

    puts "Auto-naming clusters for: #{persona.name}"
    puts ""

    clusters = Clustering::Cluster
      .joins(:photos)
      .where(photos: { persona_id: persona.id })
      .distinct

    clusters.each do |cluster|
      # Skip if already has a descriptive name (not "Cluster N")
      if cluster.name && !cluster.name.match?(/^Cluster \d+$/)
        puts "⊘ #{cluster.name} - Already named, skipping"
        next
      end

      # Get all detected objects for photos in this cluster
      objects_data = cluster.photos
        .where(persona_id: persona.id)
        .joins(:photo_analysis)
        .pluck('photo_analyses.detected_objects')
        .compact

      if objects_data.empty?
        puts "⊘ #{cluster.name} - No photo analyses, skipping"
        next
      end

      # Count object occurrences
      object_counts = Hash.new(0)
      objects_data.each do |objects|
        objects.each do |obj|
          label = obj['label']
          confidence = obj['confidence']
          # Only count objects with decent confidence
          object_counts[label] += 1 if confidence && confidence > 0.7
        end
      end

      # Filter out generic/common objects
      generic_objects = %w[person woman man clothing top floor room wall background]
      
      # Get top objects (excluding generics)
      top_objects = object_counts
        .reject { |label, _| generic_objects.include?(label.downcase) }
        .sort_by { |_, count| -count }
        .first(3)
        .map(&:first)

      if top_objects.empty?
        puts "⊘ #{cluster.name} - Only generic objects found, skipping"
        next
      end

      # Generate name from top objects
      new_name = generate_cluster_name(top_objects, object_counts[top_objects.first], cluster.photos_count)
      
      old_name = cluster.name
      cluster.update!(name: new_name)
      
      puts "✓ #{old_name} → #{new_name}"
      puts "  Top objects: #{top_objects.join(', ')}"
      puts "  Photos: #{cluster.photos_count}"
      puts ""
    end

    puts "Done!"
  end

  def generate_cluster_name(objects, primary_count, total_photos)
    # Take first 1-2 objects for the name
    primary = objects.first
    secondary = objects[1] if objects.size > 1

    # Capitalize and make it readable
    name_parts = [primary.split.map(&:capitalize).join(' ')]
    
    if secondary && objects.size > 1
      name_parts << secondary.split.map(&:capitalize).join(' ')
    end

    # Create natural-sounding name
    if name_parts.size == 1
      "#{name_parts.first} Photos"
    else
      "#{name_parts.join(' & ')} Photos"
    end
  end
end
