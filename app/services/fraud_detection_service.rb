class FraudDetectionService
  def initialize(user)
    @user = user
  end

  def analyze_betting_patterns
    bets = @user.bets.order(created_at: :desc).limit(100)
    return if bets.count < 10

    average_bet_amount = bets.average(:amount)
    standard_deviation = Math.sqrt(bets.sum { |bet| (bet.amount - average_bet_amount)**2 } / bets.size)

    threshold = 3
    suspicious_bets = bets.select { |bet| (bet.amount - average_bet_amount).abs / standard_deviation > threshold }

    suspicious_bets += detect_time_based_anomalies(bets)
    suspicious_bets += detect_frequent_betting_patterns(bets)

    if suspicious_bets.any?
      send_alert(suspicious_bets)
    end
  end

  private

  def detect_time_based_anomalies(bets)
    time_differences = bets.each_cons(2).map { |bet1, bet2| bet2.created_at - bet1.created_at }
    avg_time_diff = time_differences.sum / time_differences.size

    time_based_anomalies = bets.select do |bet|
      bet_time_diff = (bet.created_at - bets.first.created_at)
      bet_time_diff < avg_time_diff / 2 || bet_time_diff > avg_time_diff * 2
    end

    time_based_anomalies
  end

  def detect_frequent_betting_patterns(bets)
    outcome_frequency = bets.group_by(&:predicted_outcome).transform_values(&:count)
    frequent_bets = outcome_frequency.select { |outcome, count| count > 5 }

    frequent_bets.keys.map do |outcome|
      bets.select { |bet| bet.predicted_outcome == outcome }
    end.flatten
  end

  def send_alert(suspicious_bets)
    UserMailer.suspicious_betting_alert(@user, suspicious_bets).deliver_now
  end
end
