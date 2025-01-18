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


Bundler.require(*Rails.groups)

module SportsBettingApp
  class Application < Rails::Application

    config.load_defaults 6.1


    if defined?(Dotenv)
      Dotenv::Railtie.load
    end

   config.api_only = true


    config.x.jwt_secret = ENV.fetch("JWT_SECRET", Rails.application.secrets.secret_key_base)
    config.x.secret_key_base = ENV.fetch("SECRET_KEY_BASE", Rails.application.secrets.secret_key_base)

    config.cache_store = :redis_cache_store, {
      url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" },
      namespace: "sports_betting_cache"
    }


    config.middleware.use Rack::Attack
  end
end
