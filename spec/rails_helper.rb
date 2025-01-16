require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'sidekiq/testing'

Sidekiq::Testing.inline!


begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

# Configure RSpec
RSpec.configure do |config|
  # Path for test fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"


  config.use_transactional_fixtures = true

  # Infer test types (e.g., `:controller`, `:model`) from file location
  config.infer_spec_type_from_file_location!

  # Filter Rails-specific backtrace
  config.filter_rails_from_backtrace!


  config.include FactoryBot::Syntax::Methods


  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
end
