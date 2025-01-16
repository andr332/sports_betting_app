FactoryBot.define do
  factory :event do
    name { "Championship Final" }
    start_time { Time.now + 1.hour }
    odds { 1.8 }
    status { "upcoming" }
    result { 'win' }
  end
end
