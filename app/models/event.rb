class Event < ApplicationRecord
  has_many :bets, dependent: :destroy

  validates :name, presence: true
  validates :start_time, presence: true
  validates :odds, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[upcoming ongoing completed] }

  after_commit :publish_event_created, on: :create
  after_commit :publish_event_updated, on: :update
  after_destroy :publish_event_deleted

  private

  def publish_event_created
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('event_created', self.to_json)
  end

  def publish_event_updated
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('event_updated', self.to_json)
  end

  def publish_event_deleted
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('event_deleted', { id: self.id }.to_json)
  end
end
