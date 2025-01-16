class Bet < ApplicationRecord
  belongs_to :user
  belongs_to :event

  after_initialize :set_default_status, if: :new_record?

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :odds, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed canceled lost won] }

  # ✅ Fix dynamic validation error
  validates :predicted_outcome, presence: true, inclusion: { in: ->(_bet) { ResultType.pluck(:name) } }

  after_update :update_leaderboard, if: -> { saved_change_to_status? && status == 'completed' }

  after_commit :publish_bet_created, on: :create
  after_commit :publish_bet_updated, on: :update
  after_destroy :publish_bet_deleted

  def won?
    event.result == predicted_outcome
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end

  def update_leaderboard
    if won?
      winnings = amount * odds
      ProcessWinningsJob.perform_async(user_id, winnings)

      redis = Redis.new(url: ENV['REDIS_URL'])
      redis.publish('bet_winning_updated', { user_id: user_id, winnings: winnings }.to_json)

      Rails.logger.info("Bet #{id} won. User #{user_id} winnings: #{winnings}")
    else
      redis = Redis.new(url: ENV['REDIS_URL'])
      redis.publish('bet_lost', { user_id: user_id, bet_id: id }.to_json)
      Rails.logger.info("Bet #{id} was lost.")
    end
  end

  def publish_bet_created
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('bet_created', to_json)
  end

  def publish_bet_updated
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('bet_updated', to_json)
  end

  def publish_bet_deleted
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('bet_deleted', { id: id }.to_json)
  end
end
