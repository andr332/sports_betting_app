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

    context 'result validation' do
      it 'does not allow result unless event is completed' do
        event = build(:event, status: 'ongoing', result: 'win')
        expect(event).not_to be_valid
        expect(event.errors[:result]).to include('can only be set when the event is completed')
      end

      it 'allows result when the event is completed' do
        event = build(:event, status: 'completed', result: 'win')
        expect(event).to be_valid  
      end
    end
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
        event.update!(name: 'Updated Event')
        expect(redis).to have_received(:publish).with('event_updated', event.to_json)
      end
    end

    context 'when event is completed' do
      let(:event) { create(:event, status: 'ongoing', result: nil) }
      let!(:bet) { create(:bet, event: event, status: 'pending', predicted_outcome: 'win') }

      it 'does not allow updating result unless completed' do
        expect {
          event.update!(result: 'win')
        }.to raise_error(ActiveRecord::RecordInvalid)
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
