# frozen_string_literal: true

namespace :content_strategy do
  desc 'Show current strategy configuration for a persona'
  task :show, [:persona_name] => :environment do |_, args|
    persona = find_persona(args[:persona_name])
    exit 1 unless persona

    state = ContentStrategy::StrategyState.find_by(persona: persona)
    
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "  Content Strategy Status for: #{persona.name}"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if state
      puts "\nActive Strategy: #{state.active_strategy || 'Not set (using default)'}"
      puts "Started At: #{state.started_at || 'Not started'}"
      
      if state.state_data.present?
        puts "\nStrategy State:"
        state.state_data.each do |key, value|
          puts "  #{key}: #{value}"
        end
      end
      
      puts "\nConfiguration:"
      config = state.strategy_config.presence || ContentStrategy::ConfigLoader.load.as_json
      puts "  Posting frequency: #{config['posting_frequency_min']}-#{config['posting_frequency_max']}/week"
      puts "  Optimal time: #{config['optimal_time_start_hour']}:00-#{config['optimal_time_end_hour']}:00"
      puts "  Variety gap: #{config['variety_min_days_gap']} days"
      puts "  Hashtags: #{config['hashtag_count_min']}-#{config['hashtag_count_max']} tags"
    else
      puts "\nNo strategy configured yet."
      puts "Strategy will be initialized on first use."
      puts "Default: theme_of_week_strategy"
    end
    
    # Show recent posting history
    history = ContentStrategy::HistoryRecord
      .for_persona(persona.id)
      .recent_days(7)
      .limit(5)
    
    if history.any?
      puts "\nRecent Posts (last 7 days):"
      history.each do |record|
        cluster_name = record.cluster&.name || 'No cluster'
        puts "  • #{record.created_at.strftime('%Y-%m-%d')} - #{cluster_name} (#{record.strategy_name})"
      end
    else
      puts "\nNo recent posts in last 7 days."
    end
    
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  end

  desc 'Set strategy for a persona'
  task :set_strategy, [:persona_name, :strategy_name] => :environment do |_, args|
    persona = find_persona(args[:persona_name])
    exit 1 unless persona

    unless args[:strategy_name].present?
      puts "Error: strategy_name is required"
      puts "Available strategies: #{ContentStrategy::StrategyRegistry.all.join(', ')}"
      exit 1
    end

    strategy_sym = args[:strategy_name].to_sym

    unless ContentStrategy::StrategyRegistry.exists?(strategy_sym)
      puts "Error: Unknown strategy '#{args[:strategy_name]}'"
      puts "Available strategies: #{ContentStrategy::StrategyRegistry.all.join(', ')}"
      exit 1
    end

    state = ContentStrategy::StrategyState.find_or_create_by!(persona: persona)
    state.update!(
      active_strategy: args[:strategy_name],
      started_at: Time.current
    )

    puts "✓ Set strategy to '#{args[:strategy_name]}' for persona: #{persona.name}"
  end

  desc 'Reset strategy state for a persona'
  task :reset, [:persona_name] => :environment do |_, args|
    persona = find_persona(args[:persona_name])
    exit 1 unless persona

    state = ContentStrategy::StrategyState.find_by(persona: persona)
    
    if state
      state.reset_state!
      puts "✓ Reset strategy state for persona: #{persona.name}"
    else
      puts "No strategy state found for persona: #{persona.name}"
    end
  end

  desc 'List all available strategies'
  task :list_strategies => :environment do
    puts "\nAvailable Content Strategies:"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    ContentStrategy::StrategyRegistry.all.each do |strategy_name|
      strategy_class = ContentStrategy::StrategyRegistry.get(strategy_name)
      puts "\n#{strategy_name}"
      puts "  Class: #{strategy_class.name}"
      
      case strategy_name
      when :theme_of_week_strategy
        puts "  Description: Focuses on one cluster for 7 days"
        puts "  Best for: Consistent narrative, deep theme exploration"
      when :thematic_rotation_strategy
        puts "  Description: Rotates through available clusters"
        puts "  Best for: Diverse feed, showcasing variety"
      end
    end
    
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  end

  desc 'Show posting history for a persona'
  task :history, [:persona_name, :days] => :environment do |_, args|
    persona = find_persona(args[:persona_name])
    exit 1 unless persona

    days = (args[:days] || 30).to_i
    
    history = ContentStrategy::HistoryRecord
      .for_persona(persona.id)
      .recent_days(days)
      .order(created_at: :desc)
    
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "  Posting History (last #{days} days)"
    puts "  Persona: #{persona.name}"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if history.empty?
      puts "\nNo posts found in the last #{days} days."
    else
      puts "\nTotal posts: #{history.count}"
      puts "\nDetails:"
      history.each do |record|
        cluster_name = record.cluster&.name || 'No cluster'
        puts "\n  #{record.created_at.strftime('%Y-%m-%d %H:%M')}"
        puts "    Cluster: #{cluster_name}"
        puts "    Strategy: #{record.strategy_name}"
        puts "    Post ID: #{record.post_id}"
      end
    end
    
    puts "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  end

  def find_persona(persona_name)
    persona = if persona_name.present?
                Personas.find_by_name(name: persona_name)
              else
                Personas.list.first
              end

    unless persona
      if persona_name.present?
        puts "Error: Persona with name '#{persona_name}' not found."
      else
        puts 'Error: No personas found. Please create a persona first.'
      end
      return nil
    end

    persona
  end
end
