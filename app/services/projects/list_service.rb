# frozen_string_literal: true

module Projects
  class ListService
    def self.call(team:)
      new(team:).call
    end

    def initialize(team:)
      @team = team
    end

    def call
      @team.projects
           .where(archived_at: nil)
           .includes(assignee_membership: :user)
    end
  end
end
