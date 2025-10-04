# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.5'

gem 'importmap-rails'
gem 'jbuilder'
gem 'pg', '~> 1.1'
gem 'pgvector'
gem 'puma', '>= 5.0'
gem 'rails', '~> 8.0.0'
gem 'stimulus-rails'
gem 'tailwindcss-rails'
gem 'turbo-rails'

gem 'neighbor'
gem 'rumale'

gem 'faraday', '~> 2.7'
gem 'faraday-multipart'

gem 'gl_command'
gem 'packs-rails'
gem 'state_machines-activerecord'

gem 'bcrypt', '~> 3.1.7'

gem 'bootsnap', require: false

gem 'aws-sdk-s3', require: false
gem 'ruby-vips'

gem 'connection_pool'
gem 'devise'
gem 'doorkeeper'
gem 'friendly_id'
gem 'haml-rails'
gem 'sassc-rails'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'solid_queue', '~> 1.2'
gem 'sprockets-rails'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri mingw x64_mingw]

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem 'brakeman'
  gem 'dotenv-rails'
  gem 'reek'
  gem 'rspec-rails'
  gem 'rswag-specs'
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
  gem 'timecop'
  gem 'webdrivers'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'listen'
  gem 'web-console'
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'database_cleaner-active_record'
  gem 'factory_bot_rails'
  gem 'launchy'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'webmock'
end
