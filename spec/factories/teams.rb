FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "テストチーム#{n}" }
  end
end
