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
    return unless result.present?

    Rails.logger.info("Processing bets for event #{id}. Result: #{result}")

    bets.each do |bet|
      new_status = bet.predicted_outcome == result ? 'won' : 'lost'
      winnings = new_status == 'won' ? bet.amount * bet.odds : 0

      if bet.update(status: new_status, winnings: winnings)
        Rails.logger.info("Bet #{bet.id} updated to #{new_status} with winnings: #{winnings}")

        redis = Redis.new(url: ENV['REDIS_URL'])
        redis.publish('bet_status_updated', { bet_id: bet.id, status: new_status }.to_json)

        if new_status == 'won'
          leaderboard = Leaderboard.find_or_initialize_by(user_id: bet.user_id)
          leaderboard.total_winnings ||= 0
          leaderboard.total_winnings += winnings
          leaderboard.save!

          Rails.logger.info("Leaderboard for user #{bet.user_id} updated. Total winnings: #{leaderboard.total_winnings}")

          ProcessWinningsJob.perform_async(bet.user_id, winnings.to_f)
          redis.publish('bet_winning_updated', { user_id: bet.user_id, winnings: winnings.to_f, bet_id: bet.id }.to_json)
        end
      else
        Rails.logger.error("Failed to update bet #{bet.id}: #{bet.errors.full_messages.join(', ')}")
      end
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
