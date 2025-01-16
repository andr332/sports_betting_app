FactoryBot.define do
  factory :bet do
    amount { 100 }
    odds { 2.5 }
    status { "pending" }
    predicted_outcome { "win" } # Must match one of the allowed values in Event model
    association :user
    association :event
  end
end
