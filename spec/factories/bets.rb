FactoryBot.define do
  factory :bet do
    user { nil }
    event { nil }
    amount { "9.99" }
    odds { "9.99" }
    status { "MyString" }
  end
end
