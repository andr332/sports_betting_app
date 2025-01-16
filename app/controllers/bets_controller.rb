class BetsController < ApplicationController
  before_action :authenticate_user!

  # GET /users/:user_id/bets
  def index
    @bets = current_user.bets
    render json: @bets
  end

  # POST /bets
  def create
    @bet = current_user.bets.new(bet_params)

    if @bet.save
      render json: @bet, status: :created
    else
      render json: { errors: @bet.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def bet_params
    params.require(:bet).permit(:amount, :odds, :status, :event_id, :predicted_outcome) # ✅ Added predicted_outcome
  end

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    decoded_token = decode_token(token)
    @current_user = User.find(decoded_token[:user_id]) if decoded_token
  rescue JWT::DecodeError => e
    render json: { error: 'Invalid or expired token' }, status: :unauthorized
  end

  def decode_token(token)
    secret_key = ENV.fetch('JWT_SECRET', Rails.application.secrets.secret_key_base)
    JWT.decode(token, secret_key).first.symbolize_keys
  end

  def current_user
    @current_user
  end
end
