FactoryBot.define do
  factory :comment do
    association :task

    team_membership do
      association(:team_membership, team: task.project.team)
    end

    body { "テストコメント" }
  end
end
