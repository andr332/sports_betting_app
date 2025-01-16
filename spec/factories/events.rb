FactoryBot.define do
  factory :event do
    name { 'Football Match' }
    start_time { Time.now + 1.day }
    odds { 2.5 }
    status { 'upcoming' }
  end
end
