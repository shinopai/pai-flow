# frozen_string_literal: true

module Tasks
  class UpdateService
    ALLOWED_ATTRIBUTES = %i[
      title
      description
      due_date
      priority
      status
      assignee_membership_id
    ].freeze

    def self.call(task:, attributes:)
      new(task:, attributes:).call
    end

    def initialize(task:, attributes:)
      @task = task
      @attributes = attributes.to_h.symbolize_keys.slice(
        *ALLOWED_ATTRIBUTES
      )
    end

    def call
      @task.project.with_lock do
        @task.with_lock do
          validate_project_active!
          update_task!
        end
      end

      @task
    end

    private

    def validate_project_active!
      return if @task.project.archived_at.nil?

      @task.errors.add(
        :base,
        "アーカイブ済みのプロジェクトのタスクは編集できません"
      )
      raise ActiveRecord::RecordInvalid, @task
    end

    def update_task!
      attributes = @attributes.except(:assignee_membership_id)

      if @attributes.key?(:assignee_membership_id)
        membership = find_assignee_membership!
        @task.update!(attributes.merge(assignee_membership: membership))
      else
        @task.update!(attributes)
      end
    end

    def find_assignee_membership!
      membership_id = @attributes[:assignee_membership_id]

      return if membership_id.blank?

      membership = @task.project.team.team_memberships.find_by(
        id: membership_id,
        status: "active",
        role: %w[owner member]
      )

      return membership if membership

      raise_invalid_assignee_membership!
    end

    def raise_invalid_assignee_membership!
      @task.errors.add(
        :assignee_membership,
        "は同じチームの有効なOwnerまたはMemberを指定してください"
      )
      raise ActiveRecord::RecordInvalid, @task
    end
  end
end
