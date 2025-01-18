require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SportsBettingApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Load environment variables from .env if dotenv is included in the Gemfile
    if defined?(Dotenv)
      Dotenv::Railtie.load
    end

    # Only loads a smaller set of middleware suitable for API-only apps.
    config.api_only = true

    # Define the default secret keys
    config.x.jwt_secret = ENV.fetch("JWT_SECRET", Rails.application.secrets.secret_key_base)
    config.x.secret_key_base = ENV.fetch("SECRET_KEY_BASE", Rails.application.secrets.secret_key_base)

    # ✅ Use Redis as the cache store for Rack::Attack
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" },
      namespace: "sports_betting_cache"
    }


    config.middleware.use Rack::Attack
  end
end
