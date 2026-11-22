# frozen_string_literal: true

module Projects
  class CreateService
    def self.call(team:, user:, name: nil, description: nil, due_date: nil)
      new(
        team:,
        user:,
        name:,
        description:,
        due_date:
      ).call
    end

    def initialize(team:, user:, name:, description:, due_date:)
      @team = team
      @user = user
      @name = name
      @description = description
      @due_date = due_date
    end

    def call
      Team.transaction do
        membership = find_assignee_membership!
        project = build_project(membership)
        project.save!
        project
      end
    end

    private

    def find_assignee_membership!
      membership = @team.team_memberships.find_by(
        user: @user,
        status: "active",
        role: %w[owner member]
      )

      return membership if membership

      project = Project.new
      project.errors.add(:assignee_membership, "を設定できません")
      raise ActiveRecord::RecordInvalid, project
    end

    def build_project(membership)
      Project.new(
        team: @team,
        created_by: @user,
        assignee_membership: membership,
        name: @name,
        description: @description,
        due_date: @due_date,
        status: "順調"
      )
    end
  end
end
