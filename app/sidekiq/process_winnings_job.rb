class ProcessWinningsJob
  include Sidekiq::Job

  def perform(user_id, winnings)
    # Find or create the leaderboard entry for the user
    user_leaderboard = Leaderboard.find_or_create_by(user_id: user_id)

    # Ensure total_winnings is not nil before updating, default to 0 if necessary
    current_winnings = user_leaderboard.total_winnings || 0

    # Update total winnings for the user
    user_leaderboard.update(total_winnings: current_winnings + winnings)
  end
end
