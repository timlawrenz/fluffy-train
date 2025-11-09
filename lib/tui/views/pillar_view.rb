# frozen_string_literal: true

module TUI
  module Views
    class PillarView < BaseView
      def display
        loop do
          clear_screen
          print_header("Pillars & Clusters - #{persona.name}")

          show_pillars

          puts "\n#{pastel.dim('─' * 80)}"
          choice = prompt.select("What would you like to do?", per_page: 10) do |menu|
            menu.choice "Create new pillar", :create_pillar
            menu.choice "Edit pillar", :edit_pillar if ContentPillar.where(persona: persona).any?
            menu.choice "Create cluster", :create_cluster
            menu.choice "Edit cluster", :edit_cluster if Clustering::Cluster.where(persona: persona).any?
            menu.choice "Link cluster to pillar", :link_cluster if linkable_items?
            menu.choice "Add photos to cluster", :add_photos if has_clusters?
            menu.choice "Back to main menu", :back
          end

          case choice
          when :create_pillar then create_pillar
          when :edit_pillar then edit_pillar
          when :create_cluster then create_cluster
          when :edit_cluster then edit_cluster
          when :link_cluster then link_cluster
          when :add_photos then add_photos_to_cluster
          when :back then break
          end
        end
      end

      private

      def show_pillars
        pillars = ContentPillar.where(persona: persona).order(priority: :asc)

        if pillars.empty?
          puts info("No pillars created yet")
        else
          pillars.each do |pillar|
            clusters = pillar.clusters
            total_photos = clusters.sum { |c| c.photos.count }
            unposted = clusters.sum { |c| c.photos.unposted.count }

            status = total_photos > 0 ? "✅" : "🚫"
            puts "\n#{status} #{pastel.bold(pillar.name)} (#{pillar.weight}% weight, priority: #{pillar.priority})"
            puts "    #{clusters.count} clusters, #{total_photos} photos total, #{unposted} unposted"
            
            if pillar.start_date && pillar.end_date
              puts "    Active: #{pillar.start_date.strftime('%m/%d')} - #{pillar.end_date.strftime('%m/%d')}"
            end

            if total_photos < 10
              puts "    #{pastel.red('⚠️  LOW INVENTORY - need more photos!')}"
            end

            if clusters.any?
              puts "    Clusters:"
              clusters.each do |cluster|
                photos = cluster.photos.count
                unposted_cluster = cluster.photos.unposted.count
                puts "      • #{cluster.name} (#{photos} photos, #{unposted_cluster} unposted)"
              end
            end
          end
        end

        # Show unlinked clusters
        unlinked = Clustering::Cluster.where(persona: persona)
                                      .where.not(id: PillarClusterAssignment.select(:cluster_id))
                                      .order(:name)
        
        if unlinked.any?
          puts "\n#{pastel.yellow('⚠️  Unlinked Clusters')} (#{unlinked.count})"
          unlinked.each do |cluster|
            photos = cluster.photos.count
            unposted_cluster = cluster.photos.unposted.count
            puts "    • #{cluster.name} (#{photos} photos, #{unposted_cluster} unposted)"
          end
        end
      end

      def create_pillar
        clear_screen
        print_header("Create New Pillar")

        name = prompt.ask("Pillar name:", required: true)
        description = prompt.ask("Description (optional):")
        weight = prompt.ask("Weight % (total should equal 100):", convert: :float, default: 10.0)
        priority = prompt.ask("Priority (1=highest):", convert: :int, default: 5)

        use_dates = prompt.yes?("Set active date range?")
        start_date = end_date = nil

        if use_dates
          start_date = prompt.ask("Start date (YYYY-MM-DD):") { |q| q.convert :date }
          end_date = prompt.ask("End date (YYYY-MM-DD):") { |q| q.convert :date }
        end

        pillar = ContentPillar.create!(
          persona: persona,
          name: name,
          description: description,
          weight: weight,
          priority: priority,
          start_date: start_date,
          end_date: end_date
        )

        puts "\n#{success("Created pillar: #{pillar.name}")}"
        wait_for_key
      end

      def edit_pillar
        pillars = ContentPillar.where(persona: persona).order(priority: :asc)
        choices = pillars.map { |p| { name: "#{p.name} (#{p.weight}%)", value: p.id } }

        pillar_id = prompt.select("Select pillar to edit:", choices, per_page: 10)
        pillar = ContentPillar.find(pillar_id)

        clear_screen
        print_header("Edit Pillar: #{pillar.name}")

        action = prompt.select("What to change?") do |menu|
          menu.choice "Name", :name
          menu.choice "Description", :description
          menu.choice "Weight", :weight
          menu.choice "Priority", :priority
          menu.choice "Active dates", :dates
          menu.choice "Delete pillar", :delete
          menu.choice "Cancel", :cancel
        end

        case action
        when :name
          pillar.update!(name: prompt.ask("New name:", default: pillar.name))
        when :description
          pillar.update!(description: prompt.ask("New description:", default: pillar.description))
        when :weight
          pillar.update!(weight: prompt.ask("New weight %:", convert: :float, default: pillar.weight))
        when :priority
          pillar.update!(priority: prompt.ask("New priority:", convert: :int, default: pillar.priority))
        when :dates
          start_date = prompt.ask("Start date (YYYY-MM-DD):", default: pillar.start_date&.to_s) { |q| q.convert :date }
          end_date = prompt.ask("End date (YYYY-MM-DD):", default: pillar.end_date&.to_s) { |q| q.convert :date }
          pillar.update!(start_date: start_date, end_date: end_date)
        when :delete
          if prompt.yes?("Delete #{pillar.name}? This will unlink clusters but not delete them.")
            pillar.destroy
            puts success("Deleted pillar")
          end
        when :cancel
          return
        end

        puts success("Updated pillar") unless action == :delete
        wait_for_key
      end

      def create_cluster
        clear_screen
        print_header("Create New Cluster")

        name = prompt.ask("Cluster name:", required: true)

        cluster = Clustering::Cluster.create!(
          persona: persona,
          name: name
        )

        puts "\n#{success("Created cluster: #{cluster.name}")}"

        if ContentPillar.where(persona: persona).any?
          if prompt.yes?("Link to a pillar now?")
            link_cluster_to_pillar(cluster)
          end
        end

        wait_for_key
      end

      def edit_cluster
        clusters = Clustering::Cluster.where(persona: persona).order(:name)
        choices = clusters.map { |c| { name: "#{c.name} (#{c.photos.count} photos)", value: c.id } }

        cluster_id = prompt.select("Select cluster to edit:", choices, per_page: 10)
        cluster = Clustering::Cluster.find(cluster_id)

        clear_screen
        print_header("Edit Cluster: #{cluster.name}")

        action = prompt.select("What to change?") do |menu|
          menu.choice "Name", :name
          menu.choice "Link to pillar", :link if ContentPillar.where(persona: persona).any?
          menu.choice "Remove photos", :remove_photos if cluster.photos.any?
          menu.choice "Delete cluster", :delete
          menu.choice "Cancel", :cancel
        end

        case action
        when :name
          cluster.update!(name: prompt.ask("New name:", default: cluster.name))
        when :link
          link_cluster_to_pillar(cluster)
        when :remove_photos
          remove_photos_from_cluster(cluster)
        when :delete
          if prompt.yes?("Delete #{cluster.name}? Photos will remain but lose cluster assignment.")
            cluster.destroy
            puts success("Deleted cluster")
          end
        when :cancel
          return
        end

        puts success("Updated cluster") unless [:delete, :cancel].include?(action)
        wait_for_key
      end

      def link_cluster
        clusters = Clustering::Cluster.where(persona: persona).order(:name)
        choices = clusters.map { |c| { name: "#{c.name} (#{c.photos.count} photos)", value: c.id } }

        cluster_id = prompt.select("Select cluster:", choices, per_page: 10)
        cluster = Clustering::Cluster.find(cluster_id)

        link_cluster_to_pillar(cluster)
        wait_for_key
      end

      def link_cluster_to_pillar(cluster)
        pillars = ContentPillar.where(persona: persona).order(priority: :asc)
        choices = pillars.map { |p| { name: "#{p.name} (#{p.weight}%)", value: p.id } }
        choices << { name: "None (unlink)", value: nil }

        selected = prompt.multi_select("Link to which pillars? (space to select, enter to confirm):", choices, per_page: 10)

        # Remove all existing links
        PillarClusterAssignment.where(cluster: cluster).destroy_all

        # Create new links
        selected.compact.each do |pillar_id|
          pillar = ContentPillar.find(pillar_id)
          PillarClusterAssignment.create!(cluster: cluster, pillar: pillar)
        end

        puts success("Updated pillar links for #{cluster.name}")
      end

      def add_photos_to_cluster
        clusters = Clustering::Cluster.where(persona: persona).order(:name)
        choices = clusters.map { |c| { name: "#{c.name} (#{c.photos.count} photos)", value: c.id } }

        cluster_id = prompt.select("Add photos to which cluster?", choices, per_page: 10)
        cluster = Clustering::Cluster.find(cluster_id)

        # Get unassigned photos or photos from other clusters
        available = Photo.where(persona: persona).where(cluster_id: nil).or(
          Photo.where(persona: persona).where.not(cluster_id: cluster.id)
        ).order(created_at: :desc).limit(50)

        if available.empty?
          puts error("No available photos to add")
          wait_for_key
          return
        end

        clear_screen
        print_header("Add Photos to: #{cluster.name}")

        photo_choices = available.map do |photo|
          status = photo.cluster ? "(in #{photo.cluster.name})" : "(unassigned)"
          {
            name: "#{File.basename(photo.path)} #{pastel.dim(status)}",
            value: photo.id
          }
        end

        selected = prompt.multi_select("Select photos (space to select, enter to confirm):", photo_choices, per_page: 15)

        if selected.any?
          Photo.where(id: selected).update_all(cluster_id: cluster.id)
          puts success("Added #{selected.count} photos to #{cluster.name}")
        else
          puts info("No photos selected")
        end

        wait_for_key
      end

      def remove_photos_from_cluster(cluster)
        photos = cluster.photos.order(created_at: :desc)
        
        photo_choices = photos.map do |photo|
          { name: photo.filename, value: photo.id }
        end

        selected = prompt.multi_select("Remove which photos? (space to select, enter to confirm):", photo_choices, per_page: 15)

        if selected.any?
          Photo.where(id: selected).update_all(cluster_id: nil)
          puts success("Removed #{selected.count} photos from #{cluster.name}")
        end
      end

      def linkable_items?
        Clustering::Cluster.where(persona: persona).any? && ContentPillar.where(persona: persona).any?
      end

      def has_clusters?
        Clustering::Cluster.where(persona: persona).any?
      end
    end
  end
end
