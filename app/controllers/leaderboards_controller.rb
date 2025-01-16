class LeaderboardsController < ApplicationController
  include AuthenticateRequest
  before_action :authenticate_user

  # GET /leaderboard
  def index
    # Check if the leaderboard data is cached in Redis
    leaderboard = Rails.cache.fetch('leaderboard_top_10', expires_in: 1.minute) do
      # If not cached, fetch the top 10 users from the leaderboard table
      Leaderboard.includes(:user).order(total_winnings: :desc).limit(10)
    end

    # Flatten the response to include user details at the root level
    leaderboard_data = leaderboard.map do |entry|
      {
        id: entry.id,
        total_winnings: entry.total_winnings,
        name: entry.user.name,    # Flatten user data
        user_id: entry.user.id,   # Flatten user ID
        email: entry.user.email   # Include user email as well
      }
    end

    render json: leaderboard_data
  end
end
