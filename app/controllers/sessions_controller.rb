class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      token = generate_token(user)
      render json: { token: token }, status: :ok
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  private

  def generate_token(user)
    payload = { user_id: user.id, exp: 24.hours.from_now.to_i }
    secret_key = ENV['JWT_SECRET'] || Rails.application.secrets.secret_key_base
    JWT.encode(payload, secret_key)
  end
end
