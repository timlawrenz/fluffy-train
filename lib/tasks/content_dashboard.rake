# frozen_string_literal: true

namespace :content_strategy do
  desc 'Show content strategy dashboard for a persona'
  task :dashboard, [:persona_name] => :environment do |_t, args|
    persona_name = args[:persona_name] || ENV['PERSONA'] || 'sarah'
    persona = Persona.find_by(name: persona_name)

    unless persona
      puts "❌ Persona '#{persona_name}' not found"
      puts "Available personas: #{Persona.pluck(:name).join(', ')}"
      exit 1
    end

    # Current time in ET (Sarah's timezone)
    now = Time.current.in_time_zone('America/New_York')
    
    puts "\n" + "=" * 80
    puts " 📊 CONTENT STRATEGY DASHBOARD: #{persona.name.upcase}"
    puts "=" * 80
    puts "🕐 Current Time: #{now.strftime('%A, %B %d, %Y at %I:%M %p %Z')}"
    puts ""

    # ========================================================================
    # A) HOW FAR IN ADVANCE WE HAVE SCHEDULED POSTS
    # ========================================================================
    puts "📅 SCHEDULED POSTS PIPELINE"
    puts "-" * 80

    scheduled_posts = Scheduling::Post
      .where(persona: persona)
      .where(status: ['draft', 'scheduled', 'pending'])
      .order(:optimal_time_calculated, :created_at)

    if scheduled_posts.any?
      # Separate overdue from future posts
      overdue_posts = scheduled_posts.select { |p| p.optimal_time_calculated && p.optimal_time_calculated < now }
      future_posts = scheduled_posts.select { |p| !p.optimal_time_calculated || p.optimal_time_calculated >= now }
      
      if overdue_posts.any?
        puts "❌ #{overdue_posts.count} OVERDUE posts (should be marked as failed/skipped)\n"
        overdue_posts.first(3).each do |post|
          time_str = post.optimal_time_calculated.in_time_zone('America/New_York').strftime('%a %b %d, %I:%M %p ET')
          days_overdue = ((now - post.optimal_time_calculated) / 1.day).ceil
          puts "  ❌ #{time_str} (#{days_overdue} days ago)"
          puts "     Photo: #{post.photo.path.split('/').last}"
          puts "     Status: #{post.status} - Should be 'failed' or 'skipped'"
          puts ""
        end
        
        if overdue_posts.count > 3
          puts "  ... and #{overdue_posts.count - 3} more overdue posts\n"
        end
        puts "  ⚡ Action: Mark overdue posts as failed to clean up pipeline\n\n"
      end
      
      if future_posts.any?
        puts "✓ #{future_posts.count} posts scheduled ahead\n\n"
        
        future_posts.first(5).each_with_index do |post, i|
          time_str = if post.optimal_time_calculated
                       post.optimal_time_calculated.in_time_zone('America/New_York').strftime('%a %b %d, %I:%M %p ET')
                     else
                       'Not scheduled'
                     end
          
          days_away = if post.optimal_time_calculated
                        ((post.optimal_time_calculated - now) / 1.day).ceil
                      else
                        nil
                      end
          
          status_indicator = case post.status
                            when 'draft' then '📝'
                            when 'scheduled' then '⏰'
                            when 'pending' then '⏳'
                            else '❓'
                            end
          
          puts "  #{i + 1}. #{status_indicator} #{time_str}"
          puts "     Photo: #{post.photo.path.split('/').last}"
          
          if days_away
            if days_away == 0
              puts "     ⚡ TODAY"
            elsif days_away == 1
              puts "     → Tomorrow"
            else
              puts "     → In #{days_away} days"
            end
          end
          
          if post.caption
            preview = post.caption.lines.first&.strip || post.caption[0..60]
            puts "     Caption: #{preview}..."
          end
          puts ""
        end
        
        if future_posts.count > 5
          puts "  ... and #{future_posts.count - 5} more scheduled posts\n\n"
        end
      else
        puts "⚠️  No future posts scheduled\n\n"
      end

      # Coverage calculation (only for future posts)
      if future_posts.any? { |p| p.optimal_time_calculated }
        latest = future_posts.map(&:optimal_time_calculated).compact.max
        days_coverage = ((latest - now) / 1.day).ceil
        puts "✓ Content coverage: #{days_coverage} days ahead"
        
        if days_coverage < 3
          puts "⚠️  WARNING: Less than 3 days of scheduled content!"
        elsif days_coverage < 7
          puts "ℹ️  Recommend scheduling more posts soon"
        else
          puts "✅ Good coverage"
        end
      end
    else
      puts "⚠️  NO SCHEDULED POSTS"
      puts "   Run: rails content_strategy:schedule_next PERSONA=#{persona.name}"
    end

    puts "\n"

    # ========================================================================
    # B) OVERVIEW OF THE CONTENT STRATEGY
    # ========================================================================
    puts "🎯 ACTIVE CONTENT STRATEGY"
    puts "-" * 80

    state = ContentStrategy::StrategyState.find_by(persona: persona)
    
    if state&.active_strategy.present?
      puts "Strategy: #{state.active_strategy.titleize}"
      puts "Started: #{state.started_at&.strftime('%B %d, %Y') || 'Unknown'}"
      
      # Strategy-specific info
      case state.active_strategy
      when 'theme_of_week'
        week_num = state.get_state(:week_number)
        cluster_id = state.get_state(:cluster_id)
        cluster = Clustering::Cluster.find_by(id: cluster_id) if cluster_id
        
        puts "Current Week: #{week_num}"
        puts "Active Theme: #{cluster&.name || 'Not set'}"
        
        if cluster
          unposted = cluster.unposted_photos.where(persona: persona).count
          puts "Photos in theme: #{cluster.photos_count} (#{unposted} unposted)"
        end
        
      when 'thematic_rotation'
        rotation_index = state.get_state(:rotation_index) || 0
        puts "Rotation Position: #{rotation_index}"
      end
      
      # Recent posting history
      recent_posts = ContentStrategy::HistoryRecord
        .where(persona: persona)
        .order(created_at: :desc)
        .limit(5)
      
      if recent_posts.any?
        puts "\nRecent Posts (last 5):"
        recent_posts.each do |record|
          days_ago = ((now - record.created_at) / 1.day).floor
          puts "  • #{record.cluster&.name || 'No cluster'} - #{days_ago} days ago"
        end
      end
    else
      puts "⚠️  No active strategy configured"
      puts "   Default strategy will be used"
    end

    puts "\n"

    # ========================================================================
    # C) CONTENT PILLARS & CLUSTERS
    # ========================================================================
    puts "📚 CONTENT PILLARS & CLUSTERS"
    puts "-" * 80

    pillars = persona.content_pillars.active.by_priority
    
    # Get all posted photo IDs once
    posted_photo_ids = Scheduling::Post
      .where(persona: persona)
      .where.not(photo_id: nil)
      .pluck(:photo_id)
    
    if pillars.any?
      # Run gap analysis
      analyzer = ContentPillars::GapAnalyzer.new(persona: persona)
      gaps = analyzer.analyze(days_ahead: 30)
      
      puts "Active Pillars (#{pillars.count}):\n\n"
      
      pillars.each do |pillar|
        gap_data = gaps.find { |g| g[:pillar].id == pillar.id }
        
        # Pillar header
        status_icon = case gap_data&.dig(:status)
                      when :exhausted then '🚫'
                      when :critical then '🔴'
                      when :low then '⚠️ '
                      when :ready then '✅'
                      else '➖'
                      end
        
        current_indicator = pillar.current? ? '' : ' [EXPIRED]'
        date_range = if pillar.start_date || pillar.end_date
                      " (#{[pillar.start_date, pillar.end_date].compact.join(' → ')})"
                    else
                      " (Ongoing)"
                    end
        
        puts "#{status_icon} #{pillar.name}#{current_indicator}"
        puts "   Weight: #{pillar.weight}% | Priority: #{pillar.priority}/5#{date_range}"
        
        if gap_data
          puts "   Target: #{gap_data[:posts_needed]} posts | Available: #{gap_data[:photos_available]} photos | Gap: #{gap_data[:gap]}"
        end
        
        # Show clusters assigned to this pillar
        pillar_clusters = pillar.clusters.order(:name)
        
        if pillar_clusters.any?
          puts "   Clusters (#{pillar_clusters.count}):"
          
          pillar_clusters.each do |cluster|
            total_photos = cluster.photos.where(persona: persona).count
            unposted = total_photos - cluster.photos.where(id: posted_photo_ids).count
            
            cluster_status = if unposted == 0
                              "🚫"
                            elsif unposted < 3
                              "⚠️ "
                            else
                              "✅"
                            end
            
            # Check if shared with other pillars
            other_pillars = cluster.pillars.where.not(id: pillar.id)
            shared_indicator = other_pillars.any? ? " [SHARED: #{other_pillars.pluck(:name).join(', ')}]" : ""
            primary_indicator = pillar.pillar_cluster_assignments.find_by(cluster: cluster)&.primary? ? " ★" : ""
            
            puts "      #{cluster_status} #{cluster.name}#{primary_indicator}#{shared_indicator}"
            puts "         #{total_photos} photos (#{unposted} unposted)"
          end
        else
          puts "   Clusters: None assigned"
          puts "      → rails pillars:assign_cluster PILLAR_ID=#{pillar.id} CLUSTER_ID=..."
        end
        
        puts ""
      end
      
      # Summary
      total_weight = pillars.sum(:weight)
      puts "Total Active Weight: #{total_weight}%"
      
      if total_weight < 100
        puts "⚠️  Unused capacity: #{100 - total_weight}% available for new pillars"
      elsif total_weight > 100
        puts "❌ WARNING: Total weight exceeds 100%!"
      end
      
    elsif persona.clusters.any?
      # Fallback: Show clusters without pillar organization
      puts "⚠️  No active content pillars defined\n"
      puts "   Clusters exist but not organized into strategic pillars"
      puts "   Create pillar: rails pillars:create PERSONA=#{persona.name} NAME='...' WEIGHT=30\n\n"
      
      clusters = persona.clusters.order(:name)
      puts "Unorganized Clusters (#{clusters.count}):\n\n"
      
      clusters.each do |cluster|
        total_photos = cluster.photos.where(persona: persona).count
        unposted = total_photos - cluster.photos.where(id: posted_photo_ids).count
        
        status = if unposted == 0
                  "🚫"
                elsif unposted < 3
                  "⚠️ "
                else
                  "✅"
                end
        
        puts "  #{status} #{cluster.name}: #{total_photos} photos (#{unposted} unposted)"
      end
      
    else
      puts "⚠️  No content pillars or clusters found for #{persona.name}"
      puts "   1. Create pillar: rails pillars:create PERSONA=#{persona.name} NAME='...' WEIGHT=30"
      puts "   2. Create clusters: rails clustering:generate PERSONA=#{persona.name}"
      puts "   3. Assign clusters: rails pillars:assign_cluster PILLAR_ID=... CLUSTER_ID=..."
    end

    puts "\n"

    # ========================================================================
    # D) NEXT 3 ACTIONABLE ITEMS
    # ========================================================================
    puts "🎬 NEXT 3 ACTIONABLE ITEMS"
    puts "-" * 80

    actions = []
    
    # Priority 0: Clean up overdue posts (blocking issue)
    overdue_posts = scheduled_posts.select { |p| p.optimal_time_calculated && p.optimal_time_calculated < now }
    if overdue_posts.any?
      actions << {
        priority: "🔴 URGENT",
        action: "Clean up #{overdue_posts.count} overdue post(s)",
        command: "Mark as failed/skipped or reschedule",
        why: "Posts scheduled in the past are polluting the pipeline"
      }
    end
    
    # Priority 1: Content gaps from pillar analysis
    if pillars.any?
      gaps = ContentPillars::GapAnalyzer.new(persona: persona).analyze(days_ahead: 30)
      critical_gaps = gaps.select { |g| g[:priority] == :high || g[:status] == :critical }
      
      critical_gaps.first(2).each do |gap|
        actions << {
          priority: "🔴 HIGH",
          action: "Create content for #{gap[:pillar].name}",
          command: "Need #{gap[:gap]} photos for this pillar",
          why: "#{gap[:status].to_s.upcase}: Target #{gap[:posts_needed]} posts, have #{gap[:photos_available]} photos"
        }
      end
    end
    
    # Priority 2: Check if we need immediate posts
    future_posts = scheduled_posts.select { |p| !p.optimal_time_calculated || p.optimal_time_calculated >= now }
    immediate_posts = future_posts.select do |p|
      p.optimal_time_calculated && p.optimal_time_calculated < now + 24.hours
    end
    
    if future_posts.count == 0
      actions << {
        priority: "🔴 HIGH",
        action: "Schedule first post immediately",
        command: "rails content_strategy:schedule_next PERSONA=#{persona.name}",
        why: "No posts in pipeline"
      }
    elsif immediate_posts.empty? && future_posts.count < 3
      actions << {
        priority: "🟡 MEDIUM",
        action: "Schedule next post",
        command: "rails content_strategy:schedule_next PERSONA=#{persona.name}",
        why: "Only #{future_posts.count} post(s) scheduled, need buffer"
      }
    end
    
    # Priority 3: Pillar without clusters
    pillars_without_clusters = pillars.select { |p| p.clusters.count == 0 }
    if pillars_without_clusters.any?
      pillar = pillars_without_clusters.first
      actions << {
        priority: "🟡 MEDIUM",
        action: "Assign clusters to #{pillar.name} pillar",
        command: "rails pillars:assign_cluster PILLAR_ID=#{pillar.id} CLUSTER_ID=...",
        why: "Pillar has no clusters assigned yet"
      }
    end
    
    # Priority 4: Clusters without pillars (if pillars exist)
    if pillars.any?
      orphaned_clusters = persona.clusters.where.not(
        id: PillarClusterAssignment.select(:cluster_id)
      )
      
      if orphaned_clusters.any?
        actions << {
          priority: "🟢 LOW",
          action: "Organize #{orphaned_clusters.count} unassigned cluster(s)",
          command: "rails pillars:assign_cluster ...",
          why: "Clusters exist but not assigned to any pillar"
        }
      end
    end
    
    # Priority 5: No pillars defined
    if pillars.empty? && persona.clusters.any?
      actions << {
        priority: "🟡 MEDIUM",
        action: "Create content pillars for strategic organization",
        command: "rails pillars:create PERSONA=#{persona.name} NAME='...' WEIGHT=30",
        why: "Clusters exist but no strategic pillars defined"
      }
    end
    
    # Show top 3 actions
    if actions.any?
      actions.take(3).each_with_index do |item, i|
        puts "\n#{i + 1}. #{item[:priority]} #{item[:action]}"
        puts "   Why: #{item[:why]}"
        puts "   Do: #{item[:command]}"
      end
    else
      puts "\n✅ All systems running smoothly!"
      puts "   • #{scheduled_posts.count} posts scheduled"
      puts "   • Content strategy active"
      puts "   • Clusters healthy"
      puts "\n   Next: Monitor and maintain posting schedule"
    end

    puts "\n"
    puts "=" * 80
    puts ""
  end
end
