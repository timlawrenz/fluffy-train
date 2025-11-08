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
      puts "✓ #{scheduled_posts.count} posts in pipeline\n\n"
      
      scheduled_posts.each_with_index do |post, i|
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
          if days_away < 0
            puts "     ⚠️  OVERDUE by #{days_away.abs} days"
          elsif days_away == 0
            puts "     ⚡ TODAY"
          elsif days_away == 1
            puts "     → Tomorrow (#{days_away} day)"
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

      # Coverage calculation
      if scheduled_posts.any? { |p| p.optimal_time_calculated }
        latest = scheduled_posts.map(&:optimal_time_calculated).compact.max
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
    # C) CONTENT PILLARS → CLUSTERS MAPPING
    # ========================================================================
    puts "📚 CONTENT PILLARS & CLUSTERS"
    puts "-" * 80

    # Get all clusters for persona
    clusters = persona.clusters.order(:name)
    
    # Get all posted photo IDs once
    posted_photo_ids = Scheduling::Post
      .where(persona: persona)
      .where.not(photo_id: nil)
      .pluck(:photo_id)
    
    if clusters.any?
      puts "Available themes (#{clusters.count} clusters):\n\n"
      
      clusters.each do |cluster|
        total_photos = cluster.photos.where(persona: persona).count
        unposted = total_photos - cluster.photos.where(id: posted_photo_ids).count
        last_used = cluster.last_posted_at
        
        status = if unposted == 0
                  "🚫 EXHAUSTED"
                elsif last_used && (now - last_used) / 1.day < 3
                  "🔥 RECENT"
                elsif unposted < 3
                  "⚠️  LOW"
                else
                  "✅ READY"
                end
        
        puts "  #{status} #{cluster.name}"
        puts "      #{total_photos} photos total, #{unposted} unposted"
        
        if last_used
          days_since = ((now - last_used) / 1.day).floor
          puts "      Last used: #{days_since} days ago"
        else
          puts "      Last used: Never"
        end
        
        puts ""
      end
      
      # Summary stats
      total_photos = clusters.sum { |c| c.photos.where(persona: persona).count }
      total_unposted = clusters.sum do |c|
        c.photos.where(persona: persona)
         .where.not(id: posted_photo_ids)
         .count
      end
      
      puts "Total: #{total_photos} photos across #{clusters.count} themes"
      puts "Unposted: #{total_unposted} photos available"
      
      if total_unposted < 10
        puts "⚠️  WARNING: Running low on unposted content!"
      end
    else
      puts "⚠️  No clusters found for #{persona.name}"
      puts "   Run: rails clustering:generate to create clusters"
    end

    puts "\n"

    # ========================================================================
    # D) NEXT 3 ACTIONABLE ITEMS
    # ========================================================================
    puts "🎬 NEXT 3 ACTIONABLE ITEMS"
    puts "-" * 80

    actions = []
    
    # Action 1: Check if we need immediate posts
    immediate_posts = scheduled_posts.select do |p|
      p.optimal_time_calculated && p.optimal_time_calculated < now + 24.hours
    end
    
    posts_this_week = Scheduling::Post
      .where(persona: persona)
      .where('created_at >= ?', now.beginning_of_week)
      .count
    
    target_per_week = 3 # From Thanksgiving plan: 2-3/week
    
    if scheduled_posts.count == 0
      actions << {
        priority: "🔴 HIGH",
        action: "Schedule first post immediately",
        command: "rails content_strategy:schedule_next PERSONA=#{persona.name}",
        why: "No posts in pipeline"
      }
    elsif immediate_posts.empty? && scheduled_posts.count < 3
      actions << {
        priority: "🟡 MEDIUM",
        action: "Schedule next post",
        command: "rails content_strategy:schedule_next PERSONA=#{persona.name}",
        why: "Only #{scheduled_posts.count} post(s) scheduled, need buffer"
      }
    end
    
    # Action 2: Check content plan alignment
    # For Thanksgiving: We should have 9 posts scheduled through Dec 3
    if persona.name.downcase == 'sarah' && now < Time.parse('2024-12-03').in_time_zone('America/New_York')
      thanksgiving_start = Time.parse('2024-11-11').in_time_zone('America/New_York')
      thanksgiving_end = Time.parse('2024-12-03').in_time_zone('America/New_York')
      
      thanksgiving_posts = Scheduling::Post
        .where(persona: persona)
        .where('optimal_time_calculated >= ? AND optimal_time_calculated <= ?', thanksgiving_start, thanksgiving_end)
        .count
      
      if thanksgiving_posts < 9
        actions << {
          priority: "🟡 MEDIUM",
          action: "Complete Thanksgiving content plan",
          command: "Review docs/content-plans/sarah-thanksgiving-2024.md",
          why: "#{thanksgiving_posts}/9 Thanksgiving posts scheduled (need #{9 - thanksgiving_posts} more)"
        }
      end
    end
    
    # Action 3: Check cluster health
    low_clusters = clusters.select do |c|
      unposted = c.photos.where(persona: persona)
                  .where.not(id: posted_photo_ids)
                  .count
      unposted > 0 && unposted < 3
    end
    
    if low_clusters.any?
      actions << {
        priority: "🟢 LOW",
        action: "Review low-content clusters",
        command: "Check clusters: #{low_clusters.map(&:name).join(', ')}",
        why: "#{low_clusters.count} cluster(s) running low on content"
      }
    end
    
    # Action 4: Post frequency check
    if posts_this_week < target_per_week && now.wday >= 3 # Wednesday or later
      actions << {
        priority: "🟡 MEDIUM",
        action: "Maintain posting frequency",
        command: "rails content_strategy:schedule_next PERSONA=#{persona.name}",
        why: "Only #{posts_this_week}/#{target_per_week} posts this week"
      }
    end
    
    # Action 5: Caption config check
    unless persona.caption_config
      actions << {
        priority: "🟢 LOW",
        action: "Set up AI caption generation",
        command: "Configure persona.caption_config for automated captions",
        why: "Currently using fallback captions"
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
