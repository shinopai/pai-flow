FactoryBot.define do
  factory :project do
    association :team
    association :created_by, factory: :user

    name { "テストプロジェクト" }
    status { "順調" }
  end
end
