FactoryBot.define do
  factory :team_membership do
    association :team
    association :user
    role { "member" }
    status { "active" }
    joined_at { Time.current }

    trait :owner do
      role { "owner" }
    end

    trait :guest do
      role { "guest" }
    end
  end
end
