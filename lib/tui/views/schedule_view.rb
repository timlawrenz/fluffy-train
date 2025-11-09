# frozen_string_literal: true

module TUI
  module Views
    class ScheduleView < BaseView
      def display
        puts header("Schedule Post - #{persona.name}")

        result = select_next_post

        if result[:error]
          puts error(result[:error])
          wait_for_key
          return
        end

        show_preview(result)
        confirm_schedule(result)
      end

      private

      def select_next_post
        service = ContentStrategy::SelectNextPost.new(persona: persona)
        result = service.call

        if result[:error]
          return { error: result[:error] }
        end

        {
          pillar: result[:pillar],
          cluster: result[:cluster],
          photo: result[:photo],
          caption: result[:caption],
          hashtags: result[:hashtags],
          optimal_time: result[:optimal_time]
        }
      rescue StandardError => e
        { error: "Failed to select post: #{e.message}" }
      end

      def show_preview(result)
        puts section_header("POST PREVIEW")

        puts "\n#{pastel.bold('Pillar:')} #{result[:pillar]&.name || 'None'}"
        puts "#{pastel.bold('Cluster:')} #{result[:cluster]&.name || 'None'}"
        puts "#{pastel.bold('Photo:')} #{File.basename(result[:photo].path)}"
        
        if result[:optimal_time]
          puts "#{pastel.bold('Scheduled Time:')} #{result[:optimal_time].strftime('%A, %B %-d at %-I:%M %p')}"
        end

        puts "\n#{pastel.bold('Caption:')}"
        puts pastel.dim("─" * 80)
        puts result[:caption]
        puts pastel.dim("─" * 80)

        puts "\n#{pastel.bold('Hashtags:')}"
        puts result[:hashtags].join(' ')
      end

      def confirm_schedule(result)
        puts "\n" + pastel.dim("─" * 80)
        puts pastel.dim("Actions: [s] schedule  [e] edit caption  [c] cancel")

        choice = prompt.keypress("\nWhat would you like to do?", keys: [:keypress])

        case choice
        when 's'
          schedule_post(result)
        when 'e'
          edit_and_schedule(result)
        when 'c', 'q', "\e"
          puts "\n#{warning('Cancelled')}"
          wait_for_key
        else
          confirm_schedule(result) # Try again
        end
      end

      def schedule_post(result)
        scheduled_time = result[:optimal_time] || Time.now + 1.hour
        
        post = Scheduling::Post.create!(
          persona: persona,
          photo: result[:photo],
          caption: result[:caption],
          hashtags: result[:hashtags],
          scheduled_at: scheduled_time,
          status: 'scheduled',
          cluster: result[:cluster]
        )

        puts "\n#{success("Post scheduled for #{scheduled_time.strftime('%m/%d at %-I:%M %p')}")}"
        wait_for_key
      rescue StandardError => e
        puts "\n#{error("Failed to schedule: #{e.message}")}"
        wait_for_key
      end

      def edit_and_schedule(result)
        editor = ENV['EDITOR'] || 'nano'
        tmpfile = Tempfile.new(['caption', '.txt'])

        begin
          tmpfile.write(result[:caption])
          tmpfile.close

          system("#{editor} #{tmpfile.path}")

          edited_caption = File.read(tmpfile.path).strip

          if edited_caption.empty?
            puts "\n#{error('Caption cannot be empty')}"
            wait_for_key
            return
          end

          result[:caption] = edited_caption
          schedule_post(result)
        ensure
          tmpfile.unlink
        end
      end
    end
  end
end
