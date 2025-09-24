# frozen_string_literal: true

module Scheduling
  class SchedulePost < GLCommand::Chainable
    requires photo: Photo, persona: Persona, caption: String
    returns post: Scheduling::Post

    chain Scheduling::Commands::CreatePostRecord,
          Scheduling::Commands::GeneratePublicPhotoUrl,
          Scheduling::Commands::SendPostToInstagram,
          Scheduling::Commands::UpdatePostWithInstagramId
  end
end
