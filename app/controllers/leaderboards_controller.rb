class LeaderboardsController < ApplicationController
  include AuthenticateRequest
  before_action :authenticate_user

  # GET /leaderboard
  def index
    # Fetch the top 10 users from the leaderboard table, ordered by total winnings
    leaderboard = Leaderboard.order(total_winnings: :desc).limit(10)
    render json: leaderboard.as_json(include: { user: { only: [:id, :name, :email] } })
  end
end
