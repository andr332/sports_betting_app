class User < ApplicationRecord
  has_secure_password

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }

  # Associations
  has_many :bets, dependent: :destroy
  has_one :leaderboard, dependent: :destroy

  after_commit :publish_user_created, on: :create
  after_commit :publish_user_updated, on: :update
  after_destroy :publish_user_deleted

  private

  def publish_user_created
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('user_created', self.to_json)
  end

  def publish_user_updated
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('user_updated', self.to_json)
  end

  def publish_user_deleted
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('user_deleted', { id: self.id }.to_json)
  end
end
