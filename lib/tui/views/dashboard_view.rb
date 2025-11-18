# frozen_string_literal: true

require 'tty-table'

module TUI
  module Views
    class DashboardView < BaseView
      def display
        puts header("Content Dashboard - #{persona.name}")

        show_scheduled_posts
        show_pillars_status
        show_next_actions

        handle_shortcuts
      end

      private

      def show_scheduled_posts
        now = Time.current
        
        # Get posts from both scheduling methods:
        # 1. Draft posts with optimal_time_calculated (from rake task scheduling:create_scheduled_post)
        # 2. Scheduled status posts with scheduled_at (from TUI schedule view)
        draft_posts = Scheduling::Post.where(persona: persona, status: 'draft')
                                      .where.not(optimal_time_calculated: nil)
        scheduled_posts = Scheduling::Post.where(persona: persona, status: 'scheduled')
                                          .where.not(scheduled_at: nil)
        
        # Combine and sort by time
        all_posts = (draft_posts.to_a + scheduled_posts.to_a).sort_by do |post|
          post.optimal_time_calculated || post.scheduled_at
        end
        
        overdue = all_posts.select do |post|
          time = post.optimal_time_calculated || post.scheduled_at
          time < now
        end
        
        upcoming = all_posts.select do |post|
          time = post.optimal_time_calculated || post.scheduled_at
          time >= now
        end.take(5)

        puts section_header("SCHEDULED POSTS")

        if overdue.any?
          puts error("#{overdue.count} overdue posts need attention")
          overdue.take(3).each do |post|
            time = post.optimal_time_calculated || post.scheduled_at
            days = ((now - time) / 1.day).to_i
            puts "  #{pastel.red('▶')} #{time.strftime('%m/%d %H:%M')} " +
                 pastel.dim("(#{days}d ago)") + " - #{truncate(post.caption || 'No caption', 50)}"
          end
          puts pastel.dim("  ... and #{overdue.count - 3} more") if overdue.count > 3
        else
          puts success("No overdue posts")
        end

        puts ""
        if upcoming.any?
          puts info("#{upcoming.count} upcoming posts scheduled")
          upcoming.each do |post|
            time = post.optimal_time_calculated || post.scheduled_at
            days = ((time - now) / 1.day).to_i
            puts "  #{pastel.green('▶')} #{time.strftime('%m/%d %H:%M')} " +
                 pastel.dim("(in #{days}d)") + " - #{truncate(post.caption || 'No caption', 50)}"
          end
        else
          puts warning("No upcoming posts scheduled")
        end
      end

      def show_pillars_status
        pillars = persona.content_pillars.active.includes(:clusters)

        puts section_header("CONTENT PILLARS & CLUSTERS")

        if pillars.empty?
          puts warning("No active pillars defined")
          return
        end

        pillars.each do |pillar|
          clusters = pillar.clusters
          total_photos = clusters.sum { |c| c.photos.count }
          unposted = clusters.sum { |c| c.photos.unposted.count }

          status_icon = if unposted == 0
                         pastel.red('🚫')
                       elsif unposted < 5
                         pastel.yellow('⚠️ ')
                       else
                         pastel.green('✅')
                       end

          puts "\n  #{status_icon} #{pastel.bold(pillar.name)} " +
               pastel.dim("(#{pillar.weight}% weight, priority: #{pillar.priority})")
          
          if pillar.start_date && pillar.end_date
            puts "      #{pastel.dim("Active: #{pillar.start_date.strftime('%m/%d')} - #{pillar.end_date.strftime('%m/%d')}")}"
          end

          # Show clusters as tree
          if clusters.any?
            clusters.each_with_index do |cluster, idx|
              is_last = idx == clusters.count - 1
              tree_char = is_last ? '└─' : '├─'
              
              cluster_photos = cluster.photos.count
              cluster_unposted = cluster.photos.unposted.count
              
              cluster_status = if cluster_unposted == 0
                                pastel.red('○')
                              elsif cluster_unposted < 3
                                pastel.yellow('◐')
                              else
                                pastel.green('●')
                              end
              
              puts "      #{pastel.dim(tree_char)} #{cluster_status} #{cluster.name} " +
                   pastel.dim("(#{cluster_photos} photos, ") +
                   pastel.cyan("#{cluster_unposted} unposted") +
                   pastel.dim(")")
            end
          else
            puts "      #{pastel.dim('└─')} #{pastel.yellow('No clusters linked')}"
          end

          summary_line = "      #{pastel.bold('Total:')} #{clusters.count} clusters, #{total_photos} photos, " +
                        pastel.cyan("#{unposted} unposted")
          
          if unposted < 5
            summary_line += " #{warning("← LOW!")}"
          end
          
          puts summary_line
        end
      end

      def show_next_actions
        puts section_header("NEXT ACTIONS")

        actions = []

        # Check for overdue cleanup - count both types
        now = Time.current
        draft_overdue = Scheduling::Post.where(persona: persona, status: 'draft')
                                        .where.not(optimal_time_calculated: nil)
                                        .where('optimal_time_calculated < ?', now).count
        scheduled_overdue = Scheduling::Post.where(persona: persona, status: 'scheduled')
                                            .where.not(scheduled_at: nil)
                                            .where('scheduled_at < ?', now).count
        overdue_count = draft_overdue + scheduled_overdue
        
        if overdue_count > 0
          actions << {
            priority: 1,
            action: "Clean up #{overdue_count} overdue posts",
            key: 'u'
          }
        end

        # Check for low inventory pillars
        low_pillars = persona.content_pillars.active.select do |p|
          p.clusters.sum { |c| c.photos.unposted.count } < 5
        end

        if low_pillars.any?
          actions << {
            priority: 2,
            action: "Add photos to #{low_pillars.count} low-inventory pillars",
            key: 'c'
          }
        end

        # Check if ready to schedule
        if persona.content_pillars.active.any? { |p| p.clusters.any? { |c| c.photos.unposted.any? } }
          actions << {
            priority: 3,
            action: "Schedule next post",
            key: 's'
          }
        end

        # Check for pending publishes - count both types
        draft_pending = Scheduling::Post.where(persona: persona, status: 'draft')
                         .where.not(optimal_time_calculated: nil)
                         .where('optimal_time_calculated <= ?', Time.current + 1.hour).count
        scheduled_pending = Scheduling::Post.where(persona: persona, status: 'scheduled')
                           .where.not(scheduled_at: nil)
                           .where('scheduled_at <= ?', Time.current + 1.hour).count
        pending = draft_pending + scheduled_pending
        
        if pending > 0
          actions << {
            priority: 2,
            action: "Publish #{pending} ready posts",
            key: 'p'
          }
        end

        if actions.empty?
          puts info("All caught up! 🎉")
        else
          actions.sort_by { |a| a[:priority] }.take(3).each_with_index do |action, i|
            icon = i == 0 ? '🔴' : i == 1 ? '🟡' : '🔵'
            puts "  #{icon} #{action[:action]} " + pastel.dim("[press '#{action[:key]}']")
          end
        end
      end

      def handle_shortcuts
        puts "\n" + pastel.dim("─" * 80)
        puts pastel.dim("Shortcuts: [u] cleanup  [c] clusters  [s] schedule  [p] publish  [q] back")

        puts "\nPress a key or [q] to return to menu"
        
        require 'io/console'
        choice = STDIN.getch

        case choice
        when 'u'
          CleanupView.new(persona: persona).display
          display # Redisplay dashboard after action
        when 'c'
          PillarView.new(persona: persona).display
          display # Redisplay dashboard after action
        when 's'
          ScheduleView.new(persona: persona).display
          display # Redisplay dashboard after action
        when 'p'
          puts "\n#{warning('Publish view coming soon...')}"
          wait_for_key
        when 'q', "\e"
          return
        else
          display # Redisplay on unknown key
        end
      end

      def truncate(text, length)
        return text if text.length <= length

        text[0..length - 3] + "..."
      end
    end
  end
end
