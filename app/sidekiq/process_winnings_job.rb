class ProcessWinningsJob
  include Sidekiq::Job

  def perform(user_id, winnings)
    user_leaderboard = Leaderboard.find_or_create_by(user_id: user_id)

    current_winnings = user_leaderboard.total_winnings || 0

    user_leaderboard.update(total_winnings: current_winnings + winnings)
  end
end
