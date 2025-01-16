require 'rails_helper'

RSpec.describe Event, type: :model do
  let(:redis) { instance_double(Redis) }

  before do
    allow(Redis).to receive(:new).and_return(redis)
    allow(redis).to receive(:publish)
    allow(ResultType).to receive(:pluck).with(:name).and_return(%w[win lose draw penalty])
  end

  describe 'associations' do
    it { should have_many(:bets).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:odds) }
    it { should validate_numericality_of(:odds).is_greater_than(0) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[upcoming ongoing completed]) }
    it { should validate_inclusion_of(:result).in_array(%w[win lose draw penalty]).allow_nil }
  end

  describe 'callbacks' do
    let(:event) { build(:event) }

    context 'after create' do
      it 'publishes event_created event' do
        event.save!
        expect(redis).to have_received(:publish).with('event_created', event.to_json)
      end
    end

    context 'after update' do
      it 'publishes event_updated event' do
        event.save!
        event.update!(name: 'Updated Event', result: 'win')
        expect(redis).to have_received(:publish).with('event_updated', event.to_json)
      end

      it 'processes bet results when event is completed' do
        bet = create(:bet, event: event, status: 'won', predicted_outcome: 'win')
        event.save!
        event.update!(status: 'completed', result: 'win')
        expect(bet.reload.status).to eq('won')
      end
    end

    context 'after destroy' do
      it 'publishes event_deleted event' do
        event.save!
        event.destroy!
        expect(redis).to have_received(:publish).with('event_deleted', { id: event.id }.to_json)
      end
    end
  end
end
