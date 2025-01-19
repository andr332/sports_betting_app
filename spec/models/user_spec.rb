require 'rails_helper'

RSpec.describe User, type: :model do
  let(:redis) { instance_double(Redis) }

  before do
    allow(Redis).to receive(:new).and_return(redis)
    allow(redis).to receive(:publish)
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }
    it { should validate_numericality_of(:balance).is_greater_than_or_equal_to(0) } 
  end

  describe 'associations' do
    it { should have_many(:bets).dependent(:destroy) }
    it { should have_one(:leaderboard).dependent(:destroy) }
  end

  describe 'password security' do
    it 'encrypts the password' do
      user = create(:user, password: 'securepassword')
      expect(user.authenticate('securepassword')).to eq(user)
      expect(user.authenticate('wrongpassword')).to be_falsey
    end
  end

  describe 'default balance' do
    it 'assigns a default balance of 1000 when a user is created' do
      user = create(:user)
      expect(user.balance).to eq(1000)
    end
  end

  describe 'balance transactions' do
    let(:user) { create(:user, balance: 1000) }

    it 'deducts balance when a user places a bet' do
      expect { user.debit(100) }.to change { user.reload.balance }.by(-100)
    end

    it 'does not allow a debit if balance is insufficient' do
      expect(user.debit(2000)).to be false
      expect(user.reload.balance).to eq(1000)
    end

    it 'credits balance when a user wins a bet' do
      expect { user.credit(500) }.to change { user.reload.balance }.by(500)
    end
  end

  describe 'callbacks' do
    let(:user) { build(:user) }

    context 'after create' do
      it 'publishes user_created event' do
        user.save!
        expect(redis).to have_received(:publish).with('user_created', user.to_json)
      end
    end

    context 'after update' do
      it 'publishes user_updated event' do
        user.save!
        user.update!(email: 'newemail@example.com')
        expect(redis).to have_received(:publish).with('user_updated', user.to_json)
      end
    end

    context 'after destroy' do
      it 'publishes user_deleted event' do
        user.save!
        user.destroy!
        expect(redis).to have_received(:publish).with('user_deleted', { id: user.id }.to_json)
      end
    end
  end
end
