FactoryBot.define do
  factory :user do
    name { "Test User" }
    sequence(:email) { |n| "user#{n}@example.com" }  # Ensures unique emails
    password { "password123" }
  end
end
