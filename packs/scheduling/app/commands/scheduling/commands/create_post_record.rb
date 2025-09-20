# frozen_string_literal: true

module Scheduling
  module Commands
    class CreatePostRecord < GLCommand::Callable
      requires :photo, :persona, :caption
      returns :post

      def call
        context.post = Scheduling::Post.create!(
          photo: photo,
          persona: persona,
          caption: caption,
          status: 'draft'
        )
      end

      def rollback
        context.post&.destroy!
      end
    end
  end
end
