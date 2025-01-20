class Event < ApplicationRecord
  has_many :bets, dependent: :destroy

  validates :name, presence: true
  validates :start_time, presence: true
  validates :odds, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[upcoming ongoing completed] }
  validates :result, inclusion: { in: ->(event) { ResultType.pluck(:name) } }, allow_nil: true

  validate :result_can_only_be_set_for_completed_event
  before_save :prevent_early_result_assignment

  after_commit :publish_event_created, on: :create
  after_commit :publish_event_updated, on: :update
  after_destroy :publish_event_deleted
  after_update :process_bet_results, if: -> { saved_change_to_status? && status_previously_was != 'completed' && status == 'completed' }

  def bets_count
    bets.count
  end

  private

  def result_can_only_be_set_for_completed_event
    if result.present? && status != 'completed'
      errors.add(:result, "can only be set when the event is completed")
      throw(:abort)
    end
  end

  def prevent_early_result_assignment
    if status != 'completed' && result.present?
      self.result = nil
    end
  end

  def publish_event_created
    safe_publish_to_redis('event_created', to_json)
  end

  def publish_event_updated
    safe_publish_to_redis('event_updated', to_json)
  end

  def publish_event_deleted
    safe_publish_to_redis('event_deleted', { id: id }.to_json)
  end

  def safe_publish_to_redis(channel, message)
    redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
    redis.publish(channel, message)
  rescue StandardError => e
    Rails.logger.error("Redis publish error: #{e.message}")
  end

  def process_bet_results
    return unless result.present? && status == 'completed'

    Rails.logger.info("Processing bets for event #{id}. Result: #{result}")

    redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))

    bets.each do |bet|
      if bet.status == 'won'
        Rails.logger.warn("Skipping bet #{bet.id}, already won!")
        next
      end

      new_status = bet.predicted_outcome == result ? 'won' : 'lost'
      winnings = new_status == 'won' ? bet.amount * bet.odds : 0

      Rails.logger.info("Updating bet #{bet.id} from #{bet.status} to #{new_status} with winnings: #{winnings}")

      if bet.update(status: new_status, winnings: winnings)
        Rails.logger.info("Bet #{bet.id} successfully updated to #{new_status}")


        Rails.logger.info("Publishing to Redis: bet_status_updated - { bet_id: #{bet.id}, status: #{new_status} }")
        redis.publish('bet_status_updated', { bet_id: bet.id, status: new_status }.to_json)

        if new_status == 'won'
          User.transaction do
            bet.user.lock!
            bet.user.credit(winnings)
          end

          leaderboard = nil

          Leaderboard.transaction do
            leaderboard = Leaderboard.lock.find_or_initialize_by(user_id: bet.user_id)

            # Prevent adding winnings multiple times
            if leaderboard.total_winnings && leaderboard.total_winnings >= winnings
              Rails.logger.warn("Skipping leaderboard update for user #{bet.user_id}, already recorded winnings!")
            else
              leaderboard.total_winnings ||= 0
              leaderboard.total_winnings += winnings
              leaderboard.save!
            end
          end

          Rails.logger.info("Leaderboard updated for user #{bet.user_id}, Total winnings: #{leaderboard.total_winnings}")


          Rails.logger.info("Publishing to Redis: leaderboard_updated - { user_id: #{bet.user_id}, total_winnings: #{leaderboard.total_winnings} }")
          redis.publish('leaderboard_updated', { user_id: bet.user_id, total_winnings: leaderboard.total_winnings.to_f }.to_json)


          Rails.logger.info("Publishing to Redis: bet_winning_updated - { user_id: #{bet.user_id}, winnings: #{winnings.to_f}, bet_id: #{bet.id} }")
          redis.publish('bet_winning_updated', { user_id: bet.user_id, winnings: winnings.to_f, bet_id: bet.id }.to_json)
        end
      else
        Rails.logger.error("Failed to update bet #{bet.id}: #{bet.errors.full_messages.join(', ')}")
      end
    end
  end




  def update_status_based_on_time
    return if invalid?

    if start_time.past? && status != 'completed' && result.present?
      self.status = 'completed'
    elsif start_time <= Time.now && status != 'ongoing'
      self.status = 'ongoing'
    end
  end
end
