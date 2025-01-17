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
    if result.present?
      Rails.logger.info("Updating event #{id} status to 'completed' as result is set.")
      update!(status: 'completed') # Ensure event is marked as completed when the result is updated
    end

    bets.each do |bet|
      Rails.logger.info("Processing bet #{bet.id} for event #{id}. Predicted outcome: #{bet.predicted_outcome}, Actual result: #{result}")

      new_status = bet.predicted_outcome == result ? 'won' : 'lost'
      winnings = new_status == 'won' ? bet.amount * bet.odds : 0

      Rails.logger.info("Bet #{bet.id} new status: #{new_status}, Calculated winnings: #{winnings}")

      bet.update!(status: new_status, winnings: winnings)

      if new_status == 'won'
        Rails.logger.info("Updating leaderboard for user #{bet.user_id}. Adding winnings: #{winnings}")

        leaderboard = Leaderboard.find_or_initialize_by(user_id: bet.user_id)
        leaderboard.total_winnings ||= 0
        leaderboard.total_winnings += winnings
        leaderboard.save!

        Rails.logger.info("User #{bet.user_id} total winnings updated to #{leaderboard.total_winnings}")

        ProcessWinningsJob.perform_async(bet.user_id, winnings)
        redis_payload = { user_id: bet.user_id, winnings: winnings, bet_id: bet.id }.to_json
        publish_to_redis('bet_winning_updated', redis_payload)

        Rails.logger.info("Redis event 'bet_winning_updated' published: #{redis_payload}")
      else
        redis_payload = { user_id: bet.user_id, bet_id: bet.id, status: 'lost' }.to_json
        publish_to_redis('bet_lost', redis_payload)

        Rails.logger.info("Redis event 'bet_lost' published: #{redis_payload}")
      end

      Rails.logger.info("Finalized processing for bet #{bet.id}. Status: #{new_status}, Winnings: #{bet.winnings}")
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
