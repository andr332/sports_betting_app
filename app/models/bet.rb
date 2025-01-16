class Bet < ApplicationRecord
  belongs_to :user
  belongs_to :event

  after_initialize :set_default_status, if: :new_record?

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :odds, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: ['pending', 'completed', 'canceled'] }

  after_update :update_leaderboard, if: -> { saved_change_to_status? && status == 'completed' }

  after_commit :publish_bet_created, on: :create
  after_commit :publish_bet_updated, on: :update
  after_destroy :publish_bet_deleted

  def won?
    self.event.result == self.predicted_outcome
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end

  def update_leaderboard
    if won?
      winnings = amount * odds
      self.update!(status: 'completed')

      ProcessWinningsJob.perform_async(self.user_id, winnings)

      redis = Redis.new(url: ENV['REDIS_URL'])
      redis.publish('bet_winning_updated', { user_id: self.user_id, winnings: winnings }.to_json)
    else
      self.update!(status: 'lost')
      redis = Redis.new(url: ENV['REDIS_URL'])
      redis.publish('bet_lost', { user_id: self.user_id, bet_id: self.id }.to_json)

      Rails.logger.info("Bet #{self.id} was lost. Status updated.")
    end
  end


  def publish_bet_created
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('bet_created', self.to_json)
  end

  def publish_bet_updated
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('bet_updated', self.to_json)
  end

  def publish_bet_deleted
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('bet_deleted', { id: self.id }.to_json)
  end
end
