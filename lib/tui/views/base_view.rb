# frozen_string_literal: true

require 'tty-prompt'
require 'pastel'

module TUI
  module Views
    class BaseView
      attr_reader :persona, :prompt, :pastel

      def initialize(persona:)
        @persona = persona
        @prompt = TTY::Prompt.new(interrupt: :exit)
        @pastel = Pastel.new
      end

      def display
        raise NotImplementedError, "Subclasses must implement #display"
      end

      protected

      def header(title)
        "\n" +
          pastel.cyan.bold("━" * 80) + "\n" +
          pastel.cyan.bold("  #{title}") + "\n" +
          pastel.cyan.bold("━" * 80) + "\n"
      end

      def section_header(title)
        "\n" + pastel.yellow.bold("#{title}") + "\n" +
          pastel.dim("─" * 80)
      end

      def success(message)
        pastel.green("✅ #{message}")
      end

      def error(message)
        pastel.red("❌ #{message}")
      end

      def warning(message)
        pastel.yellow("⚠️  #{message}")
      end

      def info(message)
        pastel.blue("ℹ️  #{message}")
      end

      def wait_for_key
        prompt.keypress("\n#{pastel.dim('Press any key to continue...')}")
      end

      def clear_screen
        print "\e[2J\e[H"
      end

      def print_header(title)
        puts header(title)
      end
    end
  end
end
