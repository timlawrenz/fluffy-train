# frozen_string_literal: true

require 'tty-prompt'
require 'pastel'

module TUI
  class Application
    attr_reader :persona, :prompt, :pastel

    def initialize(persona:)
      @persona = persona
      @prompt = TTY::Prompt.new(interrupt: :exit)
      @pastel = Pastel.new
    end

    def run
      loop do
        choice = main_menu
        break if choice == :exit

        handle_choice(choice)
      end
    rescue Interrupt
      puts "\n#{pastel.yellow('Goodbye!')}"
    end

    private

    def main_menu
      prompt.select("\n#{header}\n\nWhat would you like to do?", cycle: true, per_page: 10) do |menu|
        menu.choice "📊 Dashboard", :dashboard
        menu.choice "🎯 Pillars & Clusters", :pillars
        menu.choice "📷 Browse Photos", :photos
        menu.choice "📅 Schedule Post", :schedule
        menu.choice "🧹 Cleanup Overdue", :cleanup
        menu.choice "❌ Exit", :exit
      end
    end

    def handle_choice(choice)
      case choice
      when :dashboard
        Views::DashboardView.new(persona: persona).display
      when :pillars
        Views::PillarView.new(persona: persona).display
      when :photos
        puts pastel.yellow("\n🚧 Photo browser coming soon...")
        prompt.keypress("\nPress any key to continue", timeout: 3)
      when :schedule
        Views::ScheduleView.new(persona: persona).display
      when :cleanup
        Views::CleanupView.new(persona: persona).display
      when :exit
        puts "\n#{pastel.green('Goodbye!')}"
      end
    end

    def header
      pastel.cyan.bold("━" * 60) + "\n" +
        pastel.cyan.bold("  Fluffy Train - Content Manager  ") + "\n" +
        pastel.cyan("  Persona: #{persona.name}") + "\n" +
        pastel.cyan.bold("━" * 60)
    end
  end
end
