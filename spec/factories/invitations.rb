FactoryBot.define do
  factory :invitation do
    association :team
    association :invitee, factory: :user
    association :invited_by, factory: :user

    email { invitee.email }
    status { "pending" }
  end
end
