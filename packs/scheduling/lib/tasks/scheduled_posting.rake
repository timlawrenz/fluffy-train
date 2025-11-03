# frozen_string_literal: true

namespace :scheduling do
  desc 'Post any scheduled posts that are due now'
  task :post_scheduled => :environment do
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "  Scheduled Post Runner"
    puts "  Time: #{Time.current.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts ""

    # Find posts that:
    # 1. Are in 'draft' status (scheduled but not posted yet)
    # 2. Have an optimal_time_calculated
    # 3. optimal_time is within the last hour (in case we missed it)
    one_hour_ago = 1.hour.ago
    now = Time.current

    scheduled_posts = Scheduling::Post
      .where(status: 'draft')
      .where.not(optimal_time_calculated: nil)
      .where('optimal_time_calculated <= ?', now)
      .where('optimal_time_calculated >= ?', one_hour_ago)
      .order(:optimal_time_calculated)

    if scheduled_posts.empty?
      puts "No posts scheduled for posting at this time."
      puts ""
      
      # Show next scheduled post
      next_post = Scheduling::Post
        .where(status: 'draft')
        .where.not(optimal_time_calculated: nil)
        .where('optimal_time_calculated > ?', now)
        .order(:optimal_time_calculated)
        .first

      if next_post
        time_until = ((next_post.optimal_time_calculated - now) / 3600).round(1)
        puts "Next scheduled post:"
        puts "  Photo: #{next_post.photo.path}"
        puts "  Scheduled: #{next_post.optimal_time_calculated.strftime('%Y-%m-%d %H:%M %Z')}"
        puts "  Time until: #{time_until} hours"
      else
        puts "No posts scheduled."
        puts ""
        puts "💡 Tip: Create scheduled posts with:"
        puts "   bundle exec rails scheduling:create_scheduled_post[sarah]"
      end
      
      puts ""
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      exit 0
    end

    puts "Found #{scheduled_posts.count} post(s) ready to publish:"
    puts ""

    scheduled_posts.each do |post|
      puts "📸 Post ID: #{post.id}"
      puts "   Photo: #{File.basename(post.photo.path)}"
      puts "   Cluster: #{post.cluster&.name || 'None'}"
      puts "   Scheduled: #{post.optimal_time_calculated.strftime('%Y-%m-%d %H:%M %Z')}"
      puts ""

      begin
        # Generate public URL for the photo
        public_url_result = Scheduling::Commands::GeneratePublicPhotoUrl.call!(photo: post.photo)
        
        if public_url_result.success?
          # Post to Instagram
          instagram_result = Scheduling::Commands::SendPostToInstagram.call!(
            public_photo_url: public_url_result.public_photo_url,
            caption: post.caption,
            persona: post.persona
          )
          
          if instagram_result.success?
            # Update post as posted
            post.update!(
              provider_post_id: instagram_result.instagram_post_id,
              posted_at: Time.current
            )
            post.mark_as_posted!
            
            puts "   ✅ Posted successfully!"
            puts "   Instagram ID: #{instagram_result.instagram_post_id}"
            
            # Record in content strategy history if applicable
            if post.cluster && post.strategy_name
              ContentStrategy::HistoryRecord.create!(
                persona: post.persona,
                post: post,
                cluster: post.cluster,
                strategy_name: post.strategy_name,
                decision_context: { scheduled_post: true }
              )
              puts "   ✅ Recorded in strategy history"
            end
          else
            post.mark_as_failed!
            puts "   ❌ Instagram posting failed: #{instagram_result.errors.join(', ')}"
            Rails.logger.error("Instagram posting failed for post #{post.id}: #{instagram_result.errors}")
          end
        else
          post.mark_as_failed!
          puts "   ❌ URL generation failed: #{public_url_result.errors}"
          Rails.logger.error("URL generation failed for post #{post.id}: #{public_url_result.errors}")
        end
      rescue StandardError => e
        post.mark_as_failed!
        puts "   ❌ Error: #{e.message}"
        Rails.logger.error("Scheduled posting error for post #{post.id}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end
      
      puts ""
    end

    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "Completed at: #{Time.current.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  end

  desc 'Create a scheduled post using content strategy'
  task :create_scheduled_post, [:persona_name] => :environment do |_, args|
    persona = if args[:persona_name].present?
                Personas.find_by_name(name: args[:persona_name])
              else
                Personas.list.first
              end

    unless persona
      puts 'Error: Persona not found'
      exit 1
    end

    puts "Creating scheduled post for: #{persona.name}"
    
    # Use content strategy to select next photo
    result = ContentStrategy::SelectNextPost.new(persona: persona).call
    
    if result[:success]
      photo = result[:photo]
      cluster = result[:cluster]
      optimal_time = result[:optimal_time]
      hashtags = result[:hashtags]
      
      # Generate caption
      caption = if photo.photo_analysis&.caption.present?
                  "#{photo.photo_analysis.caption}\n\n#{hashtags.join(' ')}"
                else
                  hashtags.join(' ')
                end
      
      # Create draft post (not posted yet)
      post = Scheduling::Post.create!(
        persona: persona,
        photo: photo,
        cluster: cluster,
        strategy_name: result[:strategy_name],
        hashtags: hashtags,
        optimal_time_calculated: optimal_time,
        caption: caption,
        status: 'draft'
      )
      
      puts ""
      puts "✅ Scheduled post created!"
      puts "   Post ID: #{post.id}"
      puts "   Photo: #{File.basename(photo.path)}"
      puts "   Cluster: #{cluster.name}"
      puts "   Strategy: #{result[:strategy_name]}"
      puts "   Scheduled for: #{optimal_time.strftime('%Y-%m-%d %H:%M %Z')}"
      puts "   Hashtags: #{hashtags.join(' ')}"
      puts ""
      
      hours_until = ((optimal_time - Time.current) / 3600).round(1)
      if hours_until > 0
        puts "📅 Will be posted in #{hours_until} hours"
      else
        puts "📅 Will be posted in next scheduled run"
      end
    else
      puts "❌ Failed to select photo: #{result[:error]}"
      exit 1
    end
  end
end
