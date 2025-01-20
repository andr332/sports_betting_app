class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :balance, numericality: { greater_than_or_equal_to: 0 }

  has_many :bets, dependent: :destroy
  has_one :leaderboard, dependent: :destroy

  before_save :downcase_email
  after_initialize :set_default_balance, if: :new_record?

  after_commit :publish_user_created, on: :create
  after_commit :publish_user_updated, on: :update
  after_destroy :publish_user_deleted

  def debit(amount)
    transaction do
      self.lock!
      if balance >= amount
        update_column(:balance, balance - amount)
        Rails.logger.info("User #{id} debited #{amount}, new balance: #{balance - amount}")
        true
      else
        Rails.logger.warn("User #{id} has insufficient balance (#{balance}) for debit of #{amount}")
        false
      end
    end
  end

  def credit(amount)
    transaction do
      self.lock!
      update_column(:balance, balance + amount) 
      Rails.logger.info("User #{id} credited #{amount}, new balance: #{balance + amount}")
    end
  end

  private

  def set_default_balance
    self.balance ||= 1000
  end

  def downcase_email
    self.email = email.to_s.downcase if email.present?
  end

  def password_required?
    new_record? || password.present?
  end

  def publish_user_created
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('user_created', to_json)
  end

  def publish_user_updated
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('user_updated', to_json)
  end

  def publish_user_deleted
    redis = Redis.new(url: ENV['REDIS_URL'])
    redis.publish('user_deleted', { id: id }.to_json)
  end
end
