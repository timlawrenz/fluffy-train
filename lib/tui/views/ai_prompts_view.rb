# frozen_string_literal: true

require_relative '../../ai/content_prompt_generator'

module TUI
  module Views
    class AIPromptsView < BaseView
      def display
        puts header("AI Content Suggestions - #{@persona.name}")
        
        loop do
          puts
          show_menu
          choice = prompt.select("What would you like to do?") do |menu|
            menu.choice "Generate cluster suggestions for a pillar", :generate
            menu.choice "View saved prompts", :view
            menu.choice "Back to main menu", :back
          end
          
          case choice
          when :generate
            generate_cluster_suggestions
          when :view
            view_saved_prompts
          when :back
            break
          end
        end
      end
      
      private
      
      def show_menu
        puts
        puts "This tool uses Gemini 2.5 Pro to generate cluster suggestions."
        puts "Each suggestion includes a cluster title and detailed creation prompt."
        puts
      end
      
      def generate_cluster_suggestions
        pillars = ContentPillar.where(persona: @persona).order(:name)
        
        if pillars.empty?
          puts pastel.yellow("\n⚠  No pillars found for #{@persona.name}")
          puts "Create pillars first in Pillars & Clusters menu."
          return
        end
        
        pillar_choices = pillars.map do |p|
          clusters = Clustering::Cluster.joins(:pillar_cluster_assignments).where(pillar_cluster_assignments: { pillar_id: p.id }).count
          photos = Photo.joins(:cluster).joins("INNER JOIN pillar_cluster_assignments ON pillar_cluster_assignments.cluster_id = clusters.id").where(pillar_cluster_assignments: { pillar_id: p.id }).count
          ["#{p.name} (#{clusters} clusters, #{photos} photos)", p.id]
        end.to_h
        
        pillar_id = prompt.select("Select pillar:", pillar_choices)
        pillar = pillars.find(pillar_id)
        
        count = prompt.ask("How many prompts to generate?", default: 3, convert: :int)
        count = [[count, 1].max, 5].min # Clamp between 1-5
        
        puts
        puts pastel.cyan("🤖 Generating #{count} cluster suggestions for: #{pillar.name}")
        puts pastel.dim("This may take 30-60 seconds...")
        puts
        
        generator = AI::ContentPromptGenerator.new(@persona)
        prompts = generator.generate_creation_prompts(pillar, count: count)
        
        if prompts.empty?
          puts pastel.red("\n✗ Failed to generate prompts")
          puts "Check that GEMINI_API_KEY is set"
          return
        end
        
        # Create clusters from generated prompts
        created_clusters = []
        prompts.each_with_index do |p, idx|
          cluster_name = generate_cluster_name(p, pillar, idx)
          
          cluster = Clustering::Cluster.create!(
            persona: @persona,
            name: cluster_name,
            ai_prompt: p[:full_prompt]
          )
          
          # Link to pillar
          PillarClusterAssignment.create!(
            pillar: pillar,
            cluster: cluster,
            primary: true
          )
          
          created_clusters << cluster
        end
        
        display_created_clusters(created_clusters, pillar)
        
        if prompt.yes?("\nAlso save prompts to a file?")
          save_prompts_to_file(prompts, pillar)
        end
      end
      
      def generate_cluster_name(prompt_data, pillar, index)
        # Try to extract a meaningful name from the scene or create a generic one
        if prompt_data[:scene] && prompt_data[:scene].length > 10
          # Take first few words of scene description
          words = prompt_data[:scene].split(/[\s,]+/).first(4).join(' ')
          words.capitalize
        else
          "#{pillar.name} - Cluster #{index + 1}"
        end
      end
      
      def display_created_clusters(clusters, pillar)
        puts
        puts pastel.bold.green("✓ Created #{clusters.size} new clusters for: #{pillar.name}")
        puts
        
        clusters.each_with_index do |cluster, idx|
          puts pastel.bold.cyan("━" * terminal_width)
          puts pastel.bold("  CLUSTER #{idx + 1}: #{cluster.name}")
          puts pastel.bold.cyan("━" * terminal_width)
          puts
          
          # Show the AI prompt
          wrapped = TTY::Box.frame(
            cluster.ai_prompt,
            padding: 1,
            border: :thick,
            title: { top_left: " AI Generation Prompt " }
          )
          puts wrapped
          puts
        end
        
        puts pastel.bold.cyan("━" * terminal_width)
        puts
        puts pastel.green("Next steps:")
        puts "  1. Use these prompts to generate images with ComfyUI/Stable Diffusion"
        puts "  2. Import the generated photos: bin/import [persona] [directory]"
        puts "  3. Add photos to these clusters in Pillars & Clusters menu"
        puts
      end
      
      def display_prompts(prompts, pillar)
        prompts.each_with_index do |p, idx|
          puts
          puts pastel.bold.cyan("━" * terminal_width)
          puts pastel.bold("  PROMPT #{idx + 1}")
          puts pastel.bold.cyan("━" * terminal_width)
          puts
          
          # Wrap the full prompt
          wrapped = TTY::Box.frame(
            p[:full_prompt],
            padding: 1,
            border: :thick,
            title: { top_left: " Image Generation Prompt " }
          )
          puts wrapped
          
          puts
          if p[:scene]
            puts pastel.green("  📍 Scene: ") + p[:scene]
          end
          if p[:outfit]
            puts pastel.magenta("  👗 Outfit: ") + p[:outfit]
          end
          if p[:mood]
            puts pastel.yellow("  ✨ Mood: ") + p[:mood]
          end
        end
        
        puts
        puts pastel.bold.cyan("━" * terminal_width)
      end
      
      def save_prompts_to_file(prompts, pillar)
        timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
        safe_pillar_name = pillar.name.downcase.gsub(/[^a-z0-9]+/, '-')
        filename = "docs/ai-prompts/#{@persona.name}_#{safe_pillar_name}_#{timestamp}.md"
        
        FileUtils.mkdir_p('docs/ai-prompts')
        
        File.open(filename, 'w') do |f|
          f.puts "# AI Content Prompts"
          f.puts
          f.puts "**Persona:** #{@persona.name}"
          f.puts "**Pillar:** #{pillar.name}"
          f.puts "**Generated:** #{Time.now.strftime('%Y-%m-%d %H:%M')}"
          f.puts
          f.puts "---"
          f.puts
          
          prompts.each_with_index do |p, idx|
            f.puts "## Prompt #{idx + 1}"
            f.puts
            f.puts p[:full_prompt]
            f.puts
            f.puts "**Scene:** #{p[:scene]}" if p[:scene]
            f.puts "**Outfit:** #{p[:outfit]}" if p[:outfit]
            f.puts "**Mood:** #{p[:mood]}" if p[:mood]
            f.puts
            f.puts "---"
            f.puts
          end
        end
        
        puts pastel.green("\n✓ Saved to: #{filename}")
      end
      
      def view_saved_prompts
        dir = 'docs/ai-prompts'
        unless Dir.exist?(dir)
          puts pastel.yellow("\n⚠  No saved prompts found")
          return
        end
        
        files = Dir.glob("#{dir}/#{@persona.name}_*.md").sort.reverse
        
        if files.empty?
          puts pastel.yellow("\n⚠  No saved prompts for #{@persona.name}")
          return
        end
        
        file_choices = files.first(10).map do |f|
          basename = File.basename(f, '.md')
          [basename, f]
        end.to_h
        
        file = prompt.select("Select file to view:", file_choices)
        
        puts
        puts pastel.cyan("━" * terminal_width)
        puts File.read(file)
        puts pastel.cyan("━" * terminal_width)
        puts
        
        prompt.keypress("\nPress any key to continue...")
      end
      
      def terminal_width
        TTY::Screen.width.clamp(80, 120)
      end
    end
  end
end
