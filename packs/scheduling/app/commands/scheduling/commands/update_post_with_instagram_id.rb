# frozen_string_literal: true

module Scheduling
  module Commands
    class UpdatePostWithInstagramId < GLCommand::Callable
      requires post: Scheduling::Post, instagram_post_id: String
      returns post: Scheduling::Post

      def call
        # Store the original state for rollback
        @original_status = post.status
        @original_provider_post_id = post.provider_post_id

        # Update the post with the instagram_post_id and transition to scheduled
        post.update!(provider_post_id: instagram_post_id)
        post.schedule! # This triggers the state machine transition from draft to scheduled

        # Return the updated post
        context.post = post
      end

      def rollback
        return unless post

        # Revert the status and clear the provider_post_id
        post.update!(
          status: @original_status,
          provider_post_id: @original_provider_post_id
        )
      end
    end
  end
end
