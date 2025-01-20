class Bet < ApplicationRecord
  belongs_to :user
  belongs_to :event

  after_initialize :set_default_status, if: :new_record?

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :odds, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed canceled lost won] }
  validates :predicted_outcome, presence: true, inclusion: { in: ->(_bet) { ResultType.pluck(:name) } }

  validate :odds_cannot_exceed_event_odds

  before_create :deduct_balance

  after_commit :publish_bet_created, on: :create
  after_commit :publish_bet_updated, on: :update
  after_destroy :publish_bet_deleted

  def won?
    event.result == predicted_outcome
  end

  private

  # Ensure odds do not exceed event odds
  def odds_cannot_exceed_event_odds
    return unless event

    if odds > event.odds
      errors.add(:odds, "cannot be higher than the event's odds (#{event.odds})")
    end
  end

  # Deduct user balance before placing a bet
  def deduct_balance
    unless user.debit(amount)
      errors.add(:base, "Insufficient balance")
      throw(:abort)
    end
  end

  def set_default_status
    self.status ||= 'pending'
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
