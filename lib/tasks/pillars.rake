# frozen_string_literal: true

namespace :pillars do
  desc 'List all content pillars for a persona'
  task :list, [:persona_name] => :environment do |_t, args|
    persona_name = args[:persona_name] || ENV['PERSONA']
    
    unless persona_name
      puts "❌ Error: PERSONA required"
      puts "Usage: rails pillars:list PERSONA=sarah"
      exit 1
    end
    
    persona = Persona.find_by(name: persona_name)
    unless persona
      puts "❌ Persona '#{persona_name}' not found"
      exit 1
    end
    
    pillars = persona.content_pillars.order(:active, :priority, :weight)
    
    if pillars.empty?
      puts "No pillars found for #{persona.name}"
      puts "Create one with: rails pillars:create PERSONA=#{persona.name} NAME='...' WEIGHT=30"
      exit 0
    end
    
    puts "\n📚 Content Pillars for #{persona.name.titleize}"
    puts "=" * 80
    
    pillars.each do |pillar|
      status = pillar.active? ? (pillar.current? ? '✅ ACTIVE' : '⏸️  PAUSED') : '❌ INACTIVE'
      
      puts "\n#{status} #{pillar.name} (ID: #{pillar.id})"
      puts "  Weight: #{pillar.weight}%"
      puts "  Priority: #{pillar.priority}/5"
      
      if pillar.start_date || pillar.end_date
        date_range = [pillar.start_date, pillar.end_date].compact.join(' → ')
        puts "  Dates: #{date_range}"
        puts "  Current: #{pillar.current? ? 'Yes' : 'No'}"
        puts "  Expired: #{pillar.expired? ? 'Yes' : 'No'}"
      end
      
      cluster_count = pillar.clusters.count
      puts "  Clusters: #{cluster_count}"
      
      if cluster_count > 0
        total_photos = pillar.clusters.joins(:photos).where(photos: { persona_id: persona.id }).distinct.count('photos.id')
        puts "  Photos: #{total_photos}"
      end
    end
    
    puts "\n" + "=" * 80
    puts "Total Weight: #{persona.content_pillars.active.sum(:weight)}%"
    puts ""
  end

  desc 'Create a new content pillar'
  task :create, [:persona_name] => :environment do |_t, args|
    persona_name = args[:persona_name] || ENV['PERSONA']
    name = ENV['NAME']
    weight = ENV['WEIGHT']
    
    unless persona_name && name && weight
      puts "❌ Error: PERSONA, NAME, and WEIGHT required"
      puts "Usage: rails pillars:create PERSONA=sarah NAME='Thanksgiving 2024' WEIGHT=30"
      puts "Optional: START_DATE=2024-11-07 END_DATE=2024-12-05 PRIORITY=3"
      exit 1
    end
    
    persona = Persona.find_by(name: persona_name)
    unless persona
      puts "❌ Persona '#{persona_name}' not found"
      exit 1
    end
    
    pillar = ContentPillar.new(
      persona: persona,
      name: name,
      weight: weight.to_f,
      start_date: ENV['START_DATE'],
      end_date: ENV['END_DATE'],
      priority: (ENV['PRIORITY'] || 3).to_i
    )
    
    if pillar.save
      puts "✅ Created pillar: #{pillar.name} (ID: #{pillar.id})"
      puts "   Weight: #{pillar.weight}%"
      puts "   Priority: #{pillar.priority}/5"
      puts "   Dates: #{[pillar.start_date, pillar.end_date].compact.join(' → ')}" if pillar.start_date || pillar.end_date
    else
      puts "❌ Failed to create pillar:"
      pillar.errors.full_messages.each { |msg| puts "   - #{msg}" }
      exit 1
    end
  end

  desc 'Show detailed information about a pillar'
  task :show, [:pillar_id] => :environment do |_t, args|
    pillar_id = args[:pillar_id] || ENV['PILLAR_ID']
    
    unless pillar_id
      puts "❌ Error: PILLAR_ID required"
      puts "Usage: rails pillars:show PILLAR_ID=1"
      exit 1
    end
    
    pillar = ContentPillar.find_by(id: pillar_id)
    unless pillar
      puts "❌ Pillar #{pillar_id} not found"
      exit 1
    end
    
    puts "\n" + "=" * 80
    puts "📌 #{pillar.name}"
    puts "=" * 80
    puts "ID: #{pillar.id}"
    puts "Persona: #{pillar.persona.name}"
    puts "Weight: #{pillar.weight}%"
    puts "Priority: #{pillar.priority}/5"
    puts "Active: #{pillar.active? ? 'Yes' : 'No'}"
    
    if pillar.start_date || pillar.end_date
      puts "\nDates:"
      puts "  Start: #{pillar.start_date || 'None'}"
      puts "  End: #{pillar.end_date || 'None'}"
      puts "  Current: #{pillar.current? ? 'Yes' : 'No'}"
      puts "  Expired: #{pillar.expired? ? 'Yes' : 'No'}"
    end
    
    if pillar.guidelines.present?
      puts "\nGuidelines:"
      pillar.guidelines.each do |key, value|
        puts "  #{key}: #{value.inspect}"
      end
    end
    
    clusters = pillar.clusters
    if clusters.any?
      puts "\nClusters (#{clusters.count}):"
      clusters.each do |cluster|
        primary = pillar.pillar_cluster_assignments.find_by(cluster: cluster)&.primary? ? ' (PRIMARY)' : ''
        photo_count = cluster.photos.where(persona_id: pillar.persona_id).count
        puts "  - #{cluster.name}#{primary} (#{photo_count} photos)"
      end
    else
      puts "\nClusters: None assigned"
      puts "  Assign with: rails pillars:assign_cluster PILLAR_ID=#{pillar.id} CLUSTER_ID=..."
    end
    puts ""
  end

  desc 'Assign a cluster to a pillar'
  task :assign_cluster => :environment do
    pillar_id = ENV['PILLAR_ID']
    cluster_id = ENV['CLUSTER_ID']
    primary = ENV['PRIMARY'] == 'true'
    
    unless pillar_id && cluster_id
      puts "❌ Error: PILLAR_ID and CLUSTER_ID required"
      puts "Usage: rails pillars:assign_cluster PILLAR_ID=1 CLUSTER_ID=5"
      puts "Optional: PRIMARY=true"
      exit 1
    end
    
    pillar = ContentPillar.find_by(id: pillar_id)
    cluster = Clustering::Cluster.find_by(id: cluster_id)
    
    unless pillar && cluster
      puts "❌ Pillar or cluster not found"
      exit 1
    end
    
    assignment = PillarClusterAssignment.new(
      pillar: pillar,
      cluster: cluster,
      primary: primary
    )
    
    if assignment.save
      puts "✅ Assigned cluster '#{cluster.name}' to pillar '#{pillar.name}'"
      puts "   Primary: #{primary ? 'Yes' : 'No'}"
    else
      puts "❌ Failed to assign cluster:"
      assignment.errors.full_messages.each { |msg| puts "   - #{msg}" }
      exit 1
    end
  end

  desc 'Remove a cluster from a pillar'
  task :remove_cluster => :environment do
    pillar_id = ENV['PILLAR_ID']
    cluster_id = ENV['CLUSTER_ID']
    
    unless pillar_id && cluster_id
      puts "❌ Error: PILLAR_ID and CLUSTER_ID required"
      puts "Usage: rails pillars:remove_cluster PILLAR_ID=1 CLUSTER_ID=5"
      exit 1
    end
    
    assignment = PillarClusterAssignment.find_by(pillar_id: pillar_id, cluster_id: cluster_id)
    
    unless assignment
      puts "❌ Assignment not found"
      exit 1
    end
    
    cluster_name = assignment.cluster.name
    pillar_name = assignment.pillar.name
    
    assignment.destroy
    puts "✅ Removed cluster '#{cluster_name}' from pillar '#{pillar_name}'"
  end

  desc 'Show content gap analysis for a persona'
  task :gaps, [:persona_name] => :environment do |_t, args|
    persona_name = args[:persona_name] || ENV['PERSONA']
    days_ahead = (ENV['DAYS'] || 30).to_i
    
    unless persona_name
      puts "❌ Error: PERSONA required"
      puts "Usage: rails pillars:gaps PERSONA=sarah"
      puts "Optional: DAYS=30"
      exit 1
    end
    
    persona = Persona.find_by(name: persona_name)
    unless persona
      puts "❌ Persona '#{persona_name}' not found"
      exit 1
    end
    
    analyzer = ContentPillars::GapAnalyzer.new(persona: persona)
    gaps = analyzer.analyze(days_ahead: days_ahead)
    
    if gaps.empty?
      puts "No active pillars for #{persona.name}"
      puts "Create one with: rails pillars:create PERSONA=#{persona.name} NAME='...' WEIGHT=30"
      exit 0
    end
    
    puts "\n📊 Content Gap Analysis for #{persona.name.titleize}"
    puts "Lookahead: #{days_ahead} days"
    puts "=" * 80
    
    gaps.each do |gap|
      status_icon = case gap[:status]
                    when :exhausted then '🚫'
                    when :critical then '🔴'
                    when :low then '⚠️ '
                    when :ready then '✅'
                    else '➖'
                    end
      
      priority_label = case gap[:priority]
                       when :high then 'HIGH'
                       when :medium then 'MED'
                       when :low then 'LOW'
                       else 'NORM'
                       end
      
      puts "\n#{status_icon} #{gap[:pillar].name} [#{priority_label}]"
      puts "   Target: #{gap[:posts_needed]} posts (#{gap[:pillar].weight}%)"
      puts "   Available: #{gap[:photos_available]} photos"
      puts "   Gap: #{gap[:gap] > 0 ? "+#{gap[:gap]}" : gap[:gap]} photos"
      
      if gap[:gap] > 0
        puts "   ⚡ Action: Create #{gap[:gap]} more photo(s)"
      elsif gap[:photos_available] < 3
        puts "   ⚠️  Warning: Low photo buffer (< 3)"
      end
    end
    
    puts "\n" + "=" * 80
    total_gap = gaps.sum { |g| [g[:gap], 0].max }
    puts "Total Content Gap: #{total_gap} photos needed"
    puts ""
  end

  desc 'Deactivate a pillar'
  task :deactivate, [:pillar_id] => :environment do |_t, args|
    pillar_id = args[:pillar_id] || ENV['PILLAR_ID']
    
    unless pillar_id
      puts "❌ Error: PILLAR_ID required"
      puts "Usage: rails pillars:deactivate PILLAR_ID=1"
      exit 1
    end
    
    pillar = ContentPillar.find_by(id: pillar_id)
    unless pillar
      puts "❌ Pillar #{pillar_id} not found"
      exit 1
    end
    
    pillar.update!(active: false)
    puts "✅ Deactivated pillar: #{pillar.name}"
  end

  desc 'Activate a pillar'
  task :activate, [:pillar_id] => :environment do |_t, args|
    pillar_id = args[:pillar_id] || ENV['PILLAR_ID']
    
    unless pillar_id
      puts "❌ Error: PILLAR_ID required"
      puts "Usage: rails pillars:activate PILLAR_ID=1"
      exit 1
    end
    
    pillar = ContentPillar.find_by(id: pillar_id)
    unless pillar
      puts "❌ Pillar #{pillar_id} not found"
      exit 1
    end
    
    pillar.update!(active: true)
    puts "✅ Activated pillar: #{pillar.name}"
  end
end
