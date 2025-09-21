# frozen_string_literal: true

module Scheduling
  module Commands
    class CreatePostRecord < GLCommand::Callable
      requires photo: Photo, persona: Persona, caption: String
      returns post: Scheduling::Post

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
