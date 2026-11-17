FactoryBot.define do
  factory :task do
    association :project
    association :created_by, factory: :user

    title { "テストタスク" }
    priority { "medium" }
    status { "not_started" }
    position { 0 }
  end
end
