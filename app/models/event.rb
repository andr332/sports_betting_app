class Event < ApplicationRecord
  has_many :bets, dependent: :destroy

  validates :name, presence: true
  validates :start_time, presence: true
  validates :odds, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[upcoming ongoing completed] }
  validates :result, presence: true, on: :update
  validates :result, inclusion: { in: %w[win lose draw], allow_nil: true }

  after_commit :publish_event_created, on: :create
  after_commit :publish_event_updated, on: :update
  after_destroy :publish_event_deleted
  after_update :process_bet_results, if: -> { saved_change_to_result? && status == 'completed' }
  before_save :update_status_based_on_time

  private

  def publish_event_created
    publish_to_redis('event_created', self.to_json)
  end

  def publish_event_updated
    publish_to_redis('event_updated', self.to_json)
  end

  def publish_event_deleted
    publish_to_redis('event_deleted', { id: self.id }.to_json)
  end

  def publish_to_redis(channel, message)
    begin
      redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
      redis.publish(channel, message)
    rescue StandardError => e
      Rails.logger.error("Redis publish error: #{e.message}")
    end
  end

  def process_bet_results
    bets.each do |bet|
      bet.update(status: 'completed')
    end
  end

  def update_status_based_on_time
    if start_time.past? && status != 'completed'
      self.status = 'completed'
    elsif start_time <= Time.now && status != 'ongoing'
      self.status = 'ongoing'  
    end
  end
end
