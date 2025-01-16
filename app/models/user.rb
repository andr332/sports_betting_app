class User < ApplicationRecord
  has_secure_password


  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }


  has_many :bets, dependent: :destroy
  has_one :leaderboard, dependent: :destroy

  before_save :downcase_email

  after_commit :publish_user_created, on: :create
  after_commit :publish_user_updated, on: :update
  after_destroy :publish_user_deleted

  private

  def downcase_email
    self.email = email.to_s.downcase if email.present?
  end


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
