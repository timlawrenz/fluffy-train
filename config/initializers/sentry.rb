# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = [:active_support_logger]
  config.dsn = 'https://69b4b22b0048a62dc1523c35cf2fbbc5@o213028.ingest.us.sentry.io/4510126608220160'
  config.traces_sample_rate = 1.0
end
