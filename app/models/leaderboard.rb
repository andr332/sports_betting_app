class Leaderboard < ApplicationRecord
  belongs_to :user

  validates :total_winnings, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
