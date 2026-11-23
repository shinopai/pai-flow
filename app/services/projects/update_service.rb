# frozen_string_literal: true

module Projects
  class UpdateService
    def self.call(project:, attributes:)
      new(project:, attributes:).call
    end

    def initialize(project:, attributes:)
      @project = project
      @attributes = attributes.to_h.symbolize_keys.slice(
        :name,
        :description,
        :due_date,
        :status,
        :assignee_membership_id
      )
    end

    def call
      @project.with_lock do
        validate_not_archived!
        update_project!
      end

      @project
    end

    private

    def validate_not_archived!
      return if @project.archived_at.nil?

      @project.errors.add(
        :base,
        "アーカイブ済みのプロジェクトは編集できません"
      )
      raise ActiveRecord::RecordInvalid, @project
    end

    def update_project!
      attributes = @attributes.except(:assignee_membership_id)

      if @attributes.key?(:assignee_membership_id)
        membership = find_assignee_membership!
        @project.update!(attributes.merge(assignee_membership: membership))
      else
        @project.update!(attributes)
      end
    end

    def find_assignee_membership!
      membership_id = @attributes[:assignee_membership_id]

      return if membership_id.blank?

      membership = @project.team.team_memberships.find_by(
        id: membership_id,
        status: "active",
        role: %w[owner member]
      )

      return membership if membership

      raise_invalid_assignee_membership!
    end

    def raise_invalid_assignee_membership!
      @project.errors.add(
        :assignee_membership,
        "は同じチームの有効なOwnerまたはMemberを指定してください"
      )
      raise ActiveRecord::RecordInvalid, @project
    end
  end
end
