class Rack::Attack
  # Store throttle counts in Redis
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" },
    namespace: "rack_attack"
  )

  ### Helper method to extract user ID from JWT ###
  def self.user_id_from_request(req)
    auth_header = req.get_header('HTTP_AUTHORIZATION')
    return nil unless auth_header.present?

    token = auth_header.split(' ').last
    begin
      decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256')
      decoded_token.first['user_id']
    rescue JWT::DecodeError
      nil
    end
  end

  ### GLOBAL RATE LIMIT ###
  throttle('req/ip', limit: 100, period: 1.minute) do |req|
    req.ip
  end

  ### AUTHENTICATION RATE LIMITS ###
  throttle('logins/ip', limit: 10, period: 1.minute) do |req|
    req.path == '/login' && req.post? ? req.ip : nil
  end

  throttle('signups/ip', limit: 5, period: 1.minute) do |req|
    req.path == '/signup' && req.post? ? req.ip : nil
  end

  ### USER-SPECIFIC RATE LIMITS (Extract user from JWT instead of session) ###
  throttle('leaderboard/user', limit: 30, period: 1.minute) do |req|
    user_id_from_request(req)
  end

  throttle('user_bets/user', limit: 20, period: 1.minute) do |req|
    user_id_from_request(req)
  end

  throttle('results/user', limit: 30, period: 1.minute) do |req|
    user_id_from_request(req)
  end

  throttle('profile/user', limit: 30, period: 1.minute) do |req|
    user_id_from_request(req)
  end

  ### LOGGING RATE LIMIT VIOLATIONS ###
  ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
    if payload[:request].env['rack.attack.match_type'] == :throttle
      Rails.logger.warn "[Rack::Attack] Throttled: #{payload[:request].env['rack.attack.match_data']}"
    end
  end

  ### RESPONSE WHEN RATE LIMITED ###
  self.throttled_response = lambda do |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [
      429,
      { 'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s },
      [{ error: "Rate limit exceeded. Try again later." }.to_json]
    ]
  end
end
