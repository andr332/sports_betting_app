require 'rails_helper'

RSpec.describe Leaderboard, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:total_winnings) }
    it { should validate_numericality_of(:total_winnings).is_greater_than_or_equal_to(0) }
  end
end
