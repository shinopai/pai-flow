module Tasks
  class CreateService
    ALLOWED_ATTRIBUTES = %i[
      title
      description
      due_date
      priority
      status
      assignee_membership_id
    ].freeze

    DEFAULT_ATTRIBUTES = {
      priority: "medium",
      status: "not_started"
    }.freeze

    def self.call(project:, user:, attributes:, parent_task: nil)
      new(
        project:,
        user:,
        attributes:,
        parent_task:
      ).call
    end

    def initialize(project:, user:, attributes:, parent_task: nil)
      @project = project
      @user = user
      @parent_task = parent_task
      @attributes = attributes.to_h.symbolize_keys
                              .slice(*ALLOWED_ATTRIBUTES)
                              .reverse_merge(DEFAULT_ATTRIBUTES)
    end

    def call
      task = nil

      @project.with_lock do
        task = build_task
        ensure_project_active!(task)
        ensure_parent_task_valid!(task)
        assign_assignee!(task)
        task.save!
      end

      task
    end

    private

    def build_task
      @project.tasks.build(
        @attributes.merge(
          parent_task: @parent_task,
          created_by: @user,
          position: next_position
        )
      )
    end

    def ensure_project_active!(task)
      return if @project.archived_at.nil?

      task.errors.add(:base, "アーカイブ済みのプロジェクトにはタスクを作成できません")
      raise ActiveRecord::RecordInvalid, task
    end

    def ensure_parent_task_valid!(task)
      return if @parent_task.nil?

      return if @parent_task.persisted? &&
                @parent_task.project_id == @project.id &&
                @parent_task.parent_task_id.nil?

      task.errors.add(:parent_task, "は同じプロジェクトの通常タスクを指定してください")
      raise ActiveRecord::RecordInvalid, task
    end

    def next_position
      @project.tasks
              .where(parent_task_id: @parent_task&.id)
              .maximum(:position)
              .to_i + 1
    end

    def assign_assignee!(task)
      return if @attributes[:assignee_membership_id].blank?

      membership = find_assignee_membership

      raise_invalid_assignee!(task) unless membership

      task.assignee_membership = membership
    end

    def find_assignee_membership
      TeamMembership.find_by(
        id: @attributes[:assignee_membership_id],
        team_id: @project.team_id,
        status: "active",
        role: %w[owner member]
      )
    end

    def raise_invalid_assignee!(task)
      task.errors.add(
        :assignee_membership_id,
        "は同じチームの有効なOwnerまたはMemberを選択してください"
      )

      raise ActiveRecord::RecordInvalid, task
    end
  end
end
