module Teams
  class CreateService
    def self.call(user:, name:)
      new(user:, name:).call
    end

    def initialize(user:, name:)
      @user = user
      @name = name
    end

    def call
      Team.transaction do
        team = Team.create!(name: @name)

        team.team_memberships.create!(
          user: @user,
          role: "owner",
          status: "active",
          joined_at: Time.current
        )

        team
      end
    end
  end
end
