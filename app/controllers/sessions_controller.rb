class SessionsController < ApplicationController
  # User Login
  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      token = generate_token(user)
      render json: {
        token: token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email
        }
      }, status: :ok
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  private

  # Generate a JWT for the User
  def generate_token(user)
    payload = { user_id: user.id, exp: 24.hours.from_now.to_i }
    secret_key = ENV.fetch('JWT_SECRET', Rails.application.secrets.secret_key_base)
    JWT.encode(payload, secret_key)
  end
end
