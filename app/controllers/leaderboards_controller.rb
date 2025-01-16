class LeaderboardsController < ApplicationController
  include AuthenticateRequest
  before_action :authenticate_user!


  def index
    leaderboard = fetch_leaderboard

    render json: leaderboard.map { |entry| format_leaderboard_entry(entry) }
  end

  private


  def fetch_leaderboard
    Rails.cache.fetch('leaderboard_top_10', expires_in: 1.minute) do
      Leaderboard.includes(:user).order(total_winnings: :desc).limit(10)
    end
  end


  def format_leaderboard_entry(entry)
    {
      id: entry.id,
      total_winnings: entry.total_winnings,
      user_id: entry.user.id,
      name: entry.user.name,
      email: entry.user.email
    }
  end
end
