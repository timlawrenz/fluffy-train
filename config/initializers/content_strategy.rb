# Initialize Content Strategy Engine
# Registers strategies and loads configuration

Rails.application.config.after_initialize do
  ContentStrategy::Engine.setup!
end
