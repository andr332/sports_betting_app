class BetsController < ApplicationController
  include AuthenticateRequest

  # Fetch all bets for the authenticated user (with event name & result)
  def index
    @bets = current_user.bets.includes(:event)
    render json: @bets.as_json(
      only: [:id, :amount, :odds, :status, :predicted_outcome],
      include: { event: { only: [:name, :result] } }
    )
  end

  # Fetch all bets for a specific user (Admin or privileged access)
  def user_bets
    user = User.find_by(id: params[:user_id])

    if user
      @bets = user.bets.includes(:event)
      render json: @bets.as_json(
        only: [:id, :amount, :odds, :status, :predicted_outcome],
        include: { event: { only: [:name, :result] } }
      )
    else
      render json: { error: "User not found" }, status: :not_found
    end
  end

  # Fetch a single bet by its ID for the authenticated user
  def show
    @bet = current_user.bets.includes(:event).find_by(id: params[:id])

    if @bet
      render json: @bet.as_json(
        only: [:id, :amount, :odds, :status, :predicted_outcome],
        include: { event: { only: [:name, :result] } }
      )
    else
      render json: { error: "Bet not found" }, status: :not_found
    end
  end

  # Place a new bet
  def create
    @bet = current_user.bets.new(bet_params)

    if @bet.save
      render json: @bet.as_json(
        only: [:id, :amount, :odds, :status, :predicted_outcome],
        include: { event: { only: [:name, :result] } }
      ), status: :created
    else
      render json: { errors: @bet.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def bet_params
    params.require(:bet).permit(:amount, :odds, :status, :event_id, :predicted_outcome)
  end
end
