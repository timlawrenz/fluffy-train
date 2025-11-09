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
        posts = persona.posts.where(status: ['scheduled', 'pending']).order(:optimal_time)
        now = Time.current

        overdue = posts.where('optimal_time < ?', now)
        upcoming = posts.where('optimal_time >= ?', now).limit(5)

        puts section_header("SCHEDULED POSTS")

        if overdue.any?
          puts error("#{overdue.count} overdue posts need attention")
          overdue.limit(3).each do |post|
            days = ((now - post.optimal_time) / 1.day).to_i
            puts "  #{pastel.red('▶')} #{post.optimal_time.strftime('%m/%d %H:%M')} " +
                 pastel.dim("(#{days}d ago)") + " - #{truncate(post.caption, 50)}"
          end
          puts pastel.dim("  ... and #{overdue.count - 3} more") if overdue.count > 3
        else
          puts success("No overdue posts")
        end

        puts ""
        if upcoming.any?
          puts info("#{upcoming.count} upcoming posts scheduled")
          upcoming.each do |post|
            days = ((post.optimal_time - now) / 1.day).to_i
            puts "  #{pastel.green('▶')} #{post.optimal_time.strftime('%m/%d %H:%M')} " +
                 pastel.dim("(in #{days}d)") + " - #{truncate(post.caption, 50)}"
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
          puts "      #{clusters.count} clusters, #{total_photos} photos total, " +
               pastel.cyan("#{unposted} unposted")

          if pillar.start_date && pillar.end_date
            puts "      #{pastel.dim("Active: #{pillar.start_date.strftime('%m/%d')} - #{pillar.end_date.strftime('%m/%d')}")}"
          end

          if unposted < 5
            puts "      #{warning("LOW INVENTORY - need more photos!")}"
          end
        end
      end

      def show_next_actions
        puts section_header("NEXT ACTIONS")

        actions = []

        # Check for overdue cleanup
        overdue_count = persona.posts.where('optimal_time < ? AND status IN (?)',
                                            Time.current, ['scheduled', 'pending']).count
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

        # Check for pending publishes
        pending = persona.posts.where(status: 'scheduled').
                         where('optimal_time <= ?', Time.current + 1.hour).count
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

        choice = prompt.keypress("\nPress a key or [q] to return to menu:", keys: [:keypress])

        case choice
        when 'u'
          CleanupView.new(persona: persona).display
          display # Redisplay dashboard after action
        when 'c'
          puts "\n#{warning('Pillars view coming soon...')}"
          wait_for_key
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
