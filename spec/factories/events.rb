FactoryBot.define do
  factory :event do
    name { "Championship Final" }
    start_time { Time.now }
    odds { 4 }
    status { "completed" }
    result { 'win' }
  end
end
