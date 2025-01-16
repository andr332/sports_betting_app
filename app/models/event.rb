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
      if bet.predicted_outcome == result
        bet.update!(status: 'won')
      else
        bet.update!(status: 'lost') 
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
