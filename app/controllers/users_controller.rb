class UsersController < ApplicationController
  include AuthenticateRequest
  skip_before_action :authenticate_user!, only: [:create]

  def create
    user = User.new(user_params)
    if user.save
      token = generate_token(user)
      render json: {
        token: token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email
        }
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def profile
    render json: {
      id: @current_user.id,
      name: @current_user.name,
      email: @current_user.email
    }
  end

  def update_profile
    if @current_user.update(user_params)
      render json: {
        id: @current_user.id,
        name: @current_user.name,
        email: @current_user.email
      }, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @current_user.destroy
      render json: { message: 'Account deleted successfully' }, status: :ok
    else
      render json: { errors: 'Unable to delete account' }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def generate_token(user)
    payload = { user_id: user.id, exp: 24.hours.from_now.to_i }
    secret_key = ENV.fetch('JWT_SECRET', Rails.application.secrets.secret_key_base)
    JWT.encode(payload, secret_key)
  end
end
