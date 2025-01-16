class Bet < ApplicationRecord
  belongs_to :user
  belongs_to :event

  # Add validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :odds, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: ['pending', 'completed', 'canceled'] }
end
