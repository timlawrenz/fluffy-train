# frozen_string_literal: true

# The public API for the scheduling pack.
module Scheduling
  # Finds all photos for a given persona that do not yet have a corresponding
  # Scheduling::Post record.
  #
  # @param persona [Personas::Persona] the persona to find unscheduled photos for
  # @return [Array<Photos::Photo>] a list of photos without scheduling posts
  def self.unscheduled_for_persona(persona:)
    # Get all photo IDs that already have a scheduling post for this persona
    scheduled_photo_ids = Scheduling::Post.where(persona: persona).pluck(:photo_id)

    # Get all photos for this persona that are not in the scheduled list
    persona.photos.where.not(id: scheduled_photo_ids).to_a
  end

  # Schedules a photo for posting to Buffer by invoking the
  # Scheduling::Chain::SchedulePost command chain.
  #
  # @param photo [Photos::Photo] the photo to schedule
  # @param persona [Personas::Persona] the persona to schedule for
  # @param caption [String] the caption for the post
  # @return [GLCommand::Context] the result of the command chain
  def self.schedule_post(photo:, persona:, caption:) # rubocop:disable Lint/UnusedMethodArgument
    # TODO: This will be implemented once Scheduling::Chain::SchedulePost exists
    # For now, return a failed context with appropriate error message
    context = GLCommand::Context.new
    context.errors.add(:base, 'Scheduling::Chain::SchedulePost command chain not yet implemented')
    context.fail!
    context
  end

  # Connects to the Buffer API to get the status for recent posts for a given
  # persona and updates the database.
  #
  # @param persona [Personas::Persona] the persona to sync statuses for
  # @return [GLCommand::Context] the result with updated posts
  def self.sync_post_statuses(persona:) # rubocop:disable Lint/UnusedMethodArgument
    # TODO: This will be implemented once Buffer::Client and sync commands exist
    # For now, return a successful context with empty updated_posts array
    context = GLCommand::Context.new
    context.updated_posts = []
    context
  end
end
