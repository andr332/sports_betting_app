class Event < ApplicationRecord
  has_many :bets, dependent: :destroy

  validates :name, presence: true
  validates :start_time, presence: true
  validates :odds, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[upcoming ongoing completed] }
  validates :result, inclusion: { in: ->(event) { ResultType.pluck(:name) }, allow_nil: true }

  after_commit :publish_event_created, on: :create
  after_commit :publish_event_updated, on: :update
  after_destroy :publish_event_deleted
  after_update :process_bet_results, if: -> { saved_change_to_result? && status == 'completed' }
  before_save :update_status_based_on_time

  def bets_count
    bets.count
  end

  private

  def publish_event_created
    publish_to_redis('event_created', to_json)
  end

  def publish_event_updated
    publish_to_redis('event_updated', to_json)
  end

  def publish_event_deleted
    publish_to_redis('event_deleted', { id: id }.to_json)
  end

  def publish_to_redis(channel, message)
    redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
    redis.publish(channel, message)
  rescue StandardError => e
    Rails.logger.error("Redis publish error: #{e.message}")
  end

  def process_bet_results
    bets.each do |bet|
      new_status = bet.predicted_outcome == result ? 'won' : 'lost'
      winnings = new_status == 'won' ? bet.amount * bet.odds : 0

      bet.update!(status: new_status, winnings: winnings)

      if new_status == 'won'
        leaderboard = Leaderboard.find_or_initialize_by(user_id: bet.user_id)
        leaderboard.total_winnings ||= 0
        leaderboard.total_winnings += winnings
        leaderboard.save!

        bet.update!(winnings: winnings) # Ensure winnings are saved in the Bet model

        ProcessWinningsJob.perform_async(bet.user_id, winnings)
        publish_to_redis('bet_winning_updated', { user_id: bet.user_id, winnings: winnings }.to_json)
      else
        publish_to_redis('bet_lost', { user_id: bet.user_id, bet_id: bet.id }.to_json)
      end

      Rails.logger.info("Bet #{bet.id} marked as #{new_status} with winnings: #{bet.winnings}.")
    end
  end

  def update_status_based_on_time
    return if invalid?

    if start_time.past? && status != 'completed'
      self.status = 'completed'
    elsif start_time <= Time.now && status != 'ongoing'
      self.status = 'ongoing'
    end
  end
end
