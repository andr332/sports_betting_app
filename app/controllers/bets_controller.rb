class BetsController < ApplicationController
  include AuthenticateRequest 

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
    params.require(:bet).permit(:amount, :odds, :status, :event_id, :predicted_outcome)
  end
end
