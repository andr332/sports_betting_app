class User < ApplicationRecord
  has_secure_password

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }

  # Associations
  has_many :bets, dependent: :destroy    # A user can place multiple bets
  has_one :leaderboard, dependent: :destroy # A user can have one leaderboard entry
end
