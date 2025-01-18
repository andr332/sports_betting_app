class ProcessWinningsJob
  include Sidekiq::Job

  def perform(user_id, winnings)
    user_leaderboard = Leaderboard.find_or_create_by(user_id: user_id)
    current_winnings = user_leaderboard.total_winnings || 0

    if user_leaderboard.update(total_winnings: current_winnings + winnings)
      Rails.logger.info("Successfully updated leaderboard for User #{user_id}: +#{winnings}")
    else
      Rails.logger.error("Failed to update leaderboard for User #{user_id}")
    end
  rescue StandardError => e
    Rails.logger.error("Error processing winnings for User #{user_id}: #{e.message}")
  end
end
