class FraudDetectionWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    FraudDetectionService.new(user).analyze_betting_patterns
  end
end
