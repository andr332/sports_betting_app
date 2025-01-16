require 'rails_helper'

RSpec.describe Bet, type: :model do
  let(:redis) { instance_double(Redis) }
  let(:user) { create(:user) }
  let(:event) { create(:event, result: 'win') }
  let(:bet) { build(:bet, user: user, event: event, amount: 100, odds: 2.5, predicted_outcome: 'win') }


  before do
    allow(Redis).to receive(:new).and_return(redis)
    allow(redis).to receive(:publish)
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:event) }
  end

  describe 'validations' do
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }

    it { should validate_presence_of(:odds) }
    it { should validate_numericality_of(:odds).is_greater_than(0) }

    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(['pending', 'completed', 'canceled']) }
  end

  describe 'callbacks' do
    context 'after initialize' do
      it 'sets default status to pending' do
        bet = Bet.new
        expect(bet.status).to eq('pending')
      end
    end

    context 'after create' do
      it 'publishes bet_created event' do
        bet.save!
        expect(redis).to have_received(:publish).with('bet_created', bet.to_json)
      end
    end

    context 'after update' do
      it 'publishes bet_updated event' do
        bet.save!
        bet.update!(amount: 200)
        expect(redis).to have_received(:publish).with('bet_updated', bet.to_json)
      end

      it 'triggers leaderboard update when bet is completed' do
        allow(ProcessWinningsJob).to receive(:perform_async)
        bet.save!
        bet.update!(status: 'completed')

        expect(redis).to have_received(:publish).with('bet_winning_updated', {
          user_id: bet.user_id,
          winnings: bet.amount * bet.odds
        }.to_json) if bet.won?

        expect(ProcessWinningsJob).to have_received(:perform_async).with(bet.user_id, bet.amount * bet.odds) if bet.won?
      end
    end

    context 'after destroy' do
      it 'publishes bet_deleted event' do
        bet.save!
        bet.destroy!
        expect(redis).to have_received(:publish).with('bet_deleted', { id: bet.id }.to_json)
      end
    end
  end

  describe '#won?' do
  it 'returns true if predicted_outcome matches event result' do
    bet.save!
    expect(bet.send(:won?)).to be true 
  end

  it 'returns false if predicted_outcome does not match event result' do
    bet.predicted_outcome = 'lose'
    bet.save!
    expect(bet.send(:won?)).to be false
  end
end

end
