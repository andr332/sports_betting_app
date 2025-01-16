class Event < ApplicationRecord
  has_many :bets, dependent: :destroy

  # ✅ Strong Validations to Ensure Data Integrity
  validates :name, presence: true
  validates :start_time, presence: true
  validates :odds, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[upcoming ongoing completed] }
  validates :result, presence: true, on: :update # Ensure result is set when updating
  validates :result, inclusion: { in: %w[win lose draw], allow_nil: true } # ✅ Ensures result is either "win", "lose", or "draw"

  # ✅ Callbacks for Redis Pub/Sub Events
  after_commit :publish_event_created, on: :create
  after_commit :publish_event_updated, on: :update
  after_destroy :publish_event_deleted
  after_update :process_bet_results, if: -> { saved_change_to_result? && status == 'completed' } # ✅ Process bets only when event is completed
  before_save :update_status_based_on_time # ✅ Update status based on start_time

  private

  # ✅ Publish event created to Redis
  def publish_event_created
    publish_to_redis('event_created', self.to_json)
  end

  # ✅ Publish event updated to Redis
  def publish_event_updated
    publish_to_redis('event_updated', self.to_json)
  end

  # ✅ Publish event deleted to Redis
  def publish_event_deleted
    publish_to_redis('event_deleted', { id: self.id }.to_json)
  end

  # ✅ Helper method to safely publish to Redis
  def publish_to_redis(channel, message)
    begin
      redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
      redis.publish(channel, message)
    rescue StandardError => e
      Rails.logger.error("Redis publish error: #{e.message}")
    end
  end

  # ✅ Process bet results when event is completed
  def process_bet_results
    bets.each do |bet|
      bet.update(status: 'completed') # Mark all bets as completed
    end
  end

  # ✅ Update event status based on the start_time
  def update_status_based_on_time
    if start_time.past? && status != 'completed'
      self.status = 'completed'  # Mark as completed if the event's start_time is in the past
    elsif start_time <= Time.now && status != 'ongoing'
      self.status = 'ongoing'  # Mark as ongoing if the event's start_time is in the present and not yet completed
    end
  end
end
