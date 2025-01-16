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
