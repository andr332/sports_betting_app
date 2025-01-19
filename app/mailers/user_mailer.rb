class UserMailer < ApplicationMailer
  default from: 'no-reply@example.com'

  def suspicious_betting_alert(user, suspicious_bets)
    @user = user
    @suspicious_bets = suspicious_bets
    mail(to: @user.email, subject: 'Suspicious Betting Activity Detected')
  end
end
