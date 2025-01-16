FactoryBot.define do
  factory :bet do
    amount { 100 }
    odds { 2.5 }
    status { "pending" }
    association :user
    association :event
  end
end
