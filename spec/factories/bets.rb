FactoryBot.define do
  factory :bet do
    amount { 100 }
    odds { 2.5 }
    status { "pending" }
    predicted_outcome { "win" }
    association :user
    association :event
  end
end
