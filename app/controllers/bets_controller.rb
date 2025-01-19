class BetsController < ApplicationController
  include AuthenticateRequest


  def index
    @bets = current_user.bets.includes(:event)
    render json: @bets.as_json(
      only: [:id, :amount, :odds, :status, :predicted_outcome],
      include: { event: { only: [:name, :result] } }
    )
  end


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


  def create
    event = Event.find_by(id: bet_params[:event_id])

    if event.nil?
      return render json: { errors: ["Event not found"] }, status: :unprocessable_entity 
    end

    @bet = current_user.bets.new(bet_params)

    # Ensure the user has enough balance before saving the bet
    if current_user.debit(@bet.amount)
      if @bet.save
        render json: @bet.as_json(
          only: [:id, :amount, :odds, :status, :predicted_outcome],
          include: { event: { only: [:name, :result] } }
        ), status: :created
      else
        current_user.credit(@bet.amount)
        render json: { errors: @bet.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { errors: ["Insufficient balance"] }, status: :unprocessable_entity
    end
  end


  private

  def bet_params
    params.require(:bet).permit(:amount, :odds, :status, :event_id, :predicted_outcome)
  end
end
