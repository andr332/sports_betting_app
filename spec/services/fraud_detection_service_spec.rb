require 'rails_helper'

RSpec.describe FraudDetectionService, type: :service do
  let(:user) { create(:user) }

  before do
    %w[win lose draw penalty].each do |name|
      ResultType.find_or_create_by!(name: name)
    end

    allow(ResultType).to receive(:pluck).with(:name).and_return(%w[win lose draw penalty])
  end

  let!(:event) { create(:event, result: "win") }  # Ensure 'win' is a valid result
  let!(:bets) { create_list(:bet, 20, user: user, amount: 50.0, event: event) }

  describe '#analyze_betting_patterns' do
    context 'when there are enough bets' do
      it 'detects suspicious bets based on Z-score threshold' do
        create(:bet, user: user, amount: 1000.0, event: event)  # This bet should be flagged as suspicious

        service = FraudDetectionService.new(user)
        service.analyze_betting_patterns

        expect(ActionMailer::Base.deliveries.count).to eq(1)  # Expect an email to be sent
      end
    end

    context 'when there are not enough bets' do
      it 'does not perform any analysis' do
        user = create(:user)
        create(:bet, user: user, amount: 50.0, event: event)  # Only 1 bet, so no analysis should be performed

        service = FraudDetectionService.new(user)
        service.analyze_betting_patterns

        expect(ActionMailer::Base.deliveries.count).to eq(0)  # No email should be sent
      end
    end
  end
end
