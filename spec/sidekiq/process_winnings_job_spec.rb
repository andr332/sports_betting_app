require 'rails_helper'
require 'sidekiq/testing' # Ensure this is required in your test

RSpec.describe ProcessWinningsJob, type: :job do
  let(:user) { create(:user) }
  let(:winnings) { 100 }

  before do
    Sidekiq::Testing.inline! # Run jobs immediately during the test
  end

  it 'updates the leaderboard with the correct winnings' do
    leaderboard = user.create_leaderboard(total_winnings: 0)

    expect {
      ProcessWinningsJob.perform_async(user.id, winnings)
    }.to change { leaderboard.reload.total_winnings }.by(winnings)
  end
end
