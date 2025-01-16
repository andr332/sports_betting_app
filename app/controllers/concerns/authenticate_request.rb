module AuthenticateRequest
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    decoded_token = decode_token(token)
    @current_user = User.find(decoded_token[:user_id]) if decoded_token
  rescue JWT::DecodeError
    render json: { error: 'Unauthorized access' }, status: :unauthorized
  end

  def decode_token(token)
    secret_key = ENV['JWT_SECRET'] || Rails.application.secrets.secret_key_base
    decoded = JWT.decode(token, secret_key, true, { algorithm: 'HS256' })
    HashWithIndifferentAccess.new(decoded[0])
  end

  def current_user
    @current_user
  end
end
