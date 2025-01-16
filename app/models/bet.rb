class Bet < ApplicationRecord
  belongs_to :user
  belongs_to :event

  # Set default status to 'pending'
  after_initialize :set_default_status, if: :new_record?

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :odds, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: ['pending', 'completed', 'canceled'] }

  # Callback after the bet status is updated to 'completed'
  after_update :update_leaderboard, if: -> { saved_change_to_status? && status == 'completed' }

  after_commit :publish_bet_created, on: :create
  after_commit :publish_bet_updated, on: :update
  after_destroy :publish_bet_deleted

  private

  # Set default status for a new bet
  def set_default_status
    self.status ||= 'pending'
  end

  # New logic to determine if the bet was won
  def won?
    self.event.result == self.predicted_outcome # Checks if the bet prediction matches the event result
  end

  def update_leaderboard
    if self.won?
      winnings = self.amount * self.odds
      # Enqueue the job to process winnings in the background
      ProcessWinningsJob.perform_async(self.user_id, winnings)

      redis = Redis.new(url: ENV['REDIS_URL'])
      redis.publish('bet_winning_updated', { user_id: self.user_id, winnings: winnings }.to_json)
    else
      Rails.logger.info("❌ Bet #{self.id} was lost. No winnings updated.")
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
