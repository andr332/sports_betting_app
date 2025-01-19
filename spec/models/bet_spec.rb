require 'rails_helper'

RSpec.describe Bet, type: :model do
  let(:redis) { instance_double(Redis) }
  let(:user) { create(:user, balance: 1000) }

  before do
    allow(Redis).to receive(:new).and_return(redis)
    allow(redis).to receive(:publish)

    allow(ResultType).to receive(:pluck).with(:name).and_return(%w[win lose draw penalty])
  end

  let(:event) { create(:event, odds: 3.0, result: 'win') }
  let(:bet) { build(:bet, user: user, event: event, amount: 100, odds: 2.5, predicted_outcome: 'win') }

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
    it { should validate_inclusion_of(:status).in_array(%w[pending completed canceled lost won]) }

    context 'custom validation - odds cannot exceed event odds' do
      it 'is valid when odds are less than or equal to event odds' do
        bet.odds = 3.0
        expect(bet).to be_valid
      end

      it 'is invalid when odds exceed event odds' do
        bet.odds = 3.5
        expect(bet).not_to be_valid
        expect(bet.errors[:odds]).to include("cannot be higher than the event's odds (3.0)")
      end
    end
  end

  describe 'callbacks' do
    context 'before create' do
      it 'deducts the user balance when a bet is placed' do
        expect { bet.save! }.to change { user.reload.balance }.by(-100)
      end

      it 'does not allow a bet if the user has insufficient balance' do
        user.update(balance: 50)
        expect(bet.save).to be false
        expect(bet.errors[:base]).to include("Insufficient balance")
      end
    end

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
      expect(bet.won?).to be true
    end

    it 'returns false if predicted_outcome does not match event result' do
      bet.predicted_outcome = 'lose'
      bet.save!
      expect(bet.won?).to be false
    end
  end

  describe 'bet winnings' do
    it 'credits the user balance when they win a bet' do
      bet.save!
      bet.update(status: "won", winnings: bet.amount * bet.odds)

      expect { bet.user.credit(bet.winnings) }.to change { user.reload.balance }.by(250)
    end

    it 'does not credit user balance when they lose a bet' do
      bet.save!
      bet.update(status: "lost", winnings: 0)

      expect { bet.user.credit(bet.winnings) }.not_to change { user.reload.balance }
    end
  end
end
