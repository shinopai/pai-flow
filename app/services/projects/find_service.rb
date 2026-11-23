# frozen_string_literal: true

module Projects
  class FindService
    def self.call(team:, id:)
      new(team:, id:).call
    end

    def initialize(team:, id:)
      @team = team
      @id = id
    end

    def call
      @team.projects
           .includes(assignee_membership: :user)
           .find(@id)
    end
  end
end
