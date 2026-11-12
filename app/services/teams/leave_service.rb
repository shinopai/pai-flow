module Teams
  class LeaveService
    def self.call(team_membership:)
      new(team_membership:).call
    end

    def initialize(team_membership:)
      @team_membership = team_membership
    end

    def call
      @team_membership.team.with_lock do
        load_membership!
        validate_membership!
        unassign_records!
        leave_team!
      end
    end

    private

    def load_membership!
      @team_membership = @team_membership.team
                                         .team_memberships
                                         .lock
                                         .find(@team_membership.id)
    end

    def validate_membership!
      validate_active!
      validate_not_owner!
    end

    def validate_active!
      return if @team_membership.status == "active"

      @team_membership.errors.add(
        :base,
        "このチームには所属していません"
      )
      raise ActiveRecord::RecordInvalid, @team_membership
    end

    def validate_not_owner!
      return unless @team_membership.role == "owner"

      @team_membership.errors.add(
        :base,
        "Ownerは先にOwner権限を移譲してください"
      )
      raise ActiveRecord::RecordInvalid, @team_membership
    end

    def unassign_records!
      @team_membership.assigned_projects.find_each do |project|
        project.update!(assignee_membership: nil)
      end

      @team_membership.assigned_tasks.find_each do |task|
        task.update!(assignee_membership: nil)
      end
    end

    def leave_team!
      @team_membership.update!(
        status: "left",
        left_at: Time.current
      )
    end
  end
end
