# frozen_string_literal: true

module TUI
  module Views
    class CleanupView < BaseView
      def display
        puts header("Cleanup Overdue Posts - #{persona.name}")

        posts = fetch_overdue_posts

        if posts.empty?
          puts success("No overdue posts to clean up!")
          wait_for_key
          return
        end

        show_overdue_list(posts)
        handle_cleanup(posts)
      end

      private

      def fetch_overdue_posts
        Scheduling::Post.where(persona: persona)
               .where('scheduled_at < ?', Time.current)
               .where(status: ['scheduled', 'pending'])
               .order(:scheduled_at)
      end

      def show_overdue_list(posts)
        puts section_header("OVERDUE POSTS")

        now = Time.current
        posts.each_with_index do |post, i|
          days = ((now - post.scheduled_at) / 1.day).to_i
          puts "  #{i + 1}. #{post.scheduled_at.strftime('%m/%d %H:%M')} " +
               pastel.red("(#{days}d overdue)") +
               " - #{truncate(post.caption || 'No caption', 50)}"
        end

        puts "\n#{warning("Total: #{posts.count} overdue posts")}"
      end

      def handle_cleanup(posts)
        puts "\n" + pastel.dim("─" * 80)
        puts pastel.dim("Actions: [f] mark all as failed  [s] select posts  [c] cancel")

        choice = prompt.keypress("\nWhat would you like to do?", keys: [:keypress])

        case choice
        when 'f'
          mark_all_failed(posts)
        when 's'
          select_and_mark(posts)
        when 'c', 'q', "\e"
          puts "\n#{warning('Cancelled')}"
          wait_for_key
        else
          handle_cleanup(posts) # Try again
        end
      end

      def mark_all_failed(posts)
        return unless confirm_action("Mark all #{posts.count} posts as failed?")

        posts.update_all(status: 'failed', updated_at: Time.current)

        puts "\n#{success("Marked #{posts.count} posts as failed")}"
        wait_for_key
      end

      def select_and_mark(posts)
        choices = posts.map.with_index do |post, i|
          days = ((Time.current - post.scheduled_at) / 1.day).to_i
          {
            name: "#{post.scheduled_at.strftime('%m/%d %H:%M')} (#{days}d overdue) - #{truncate(post.caption || 'No caption', 40)}",
            value: post.id
          }
        end

        selected = prompt.multi_select(
          "Select posts to mark as failed:",
          choices,
          per_page: 15,
          echo: false
        )

        if selected.empty?
          puts "\n#{warning('No posts selected')}"
          wait_for_key
          return
        end

        return unless confirm_action("Mark #{selected.count} posts as failed?")

        Scheduling::Post.where(id: selected).update_all(status: 'failed', updated_at: Time.current)

        puts "\n#{success("Marked #{selected.count} posts as failed")}"
        wait_for_key
      end

      def confirm_action(message)
        prompt.yes?("\n#{message}")
      end

      def truncate(text, length)
        return text if text.length <= length

        text[0..length - 3] + "..."
      end
    end
  end
end
