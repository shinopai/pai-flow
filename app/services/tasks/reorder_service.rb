# frozen_string_literal: true

module Tasks
  class ReorderService
    def self.call(project:, task_ids:, parent_task_id: nil)
      new(
        project: project,
        task_ids: task_ids,
        parent_task_id: parent_task_id
      ).call
    end

    def initialize(project:, task_ids:, parent_task_id:)
      @project = project
      @task_ids = task_ids
      @parent_task_id = parent_task_id
    end

    def call
      @project.with_lock do
        validate_project_active!
        validate_task_ids_format!
        find_parent_task! if @parent_task_id.present?

        reorder_tasks!(target_tasks.lock.to_a)
      end
    end

    private

    def target_tasks
      @project.tasks.where(parent_task_id: @parent_task_id)
    end

    def find_parent_task!
      @project.tasks
              .where(parent_task_id: nil)
              .find(@parent_task_id)
    end

    def validate_project_active!
      return if @project.archived_at.nil?

      raise_invalid!("アーカイブ済みのプロジェクトは並び替えできません")
    end

    def validate_task_ids_format!
      return if @task_ids.is_a?(Array) &&
                @task_ids.all? { |id| id.to_s.match?(/\A[1-9]\d*\z/) }

      raise_invalid!("並び替え対象のタスクが正しくありません")
    end

    def reorder_tasks!(tasks)
      validate_task_ids!(tasks)

      tasks_by_id = tasks.index_by { |task| task.id.to_s }

      @task_ids.each_with_index do |task_id, index|
        tasks_by_id.fetch(task_id.to_s).update!(position: index)
      end
    end

    def validate_task_ids!(tasks)
      submitted_ids = @task_ids.map(&:to_s)
      expected_ids = tasks.map { |task| task.id.to_s }

      return if submitted_ids.uniq.size == submitted_ids.size &&
                submitted_ids.sort == expected_ids.sort

      raise_invalid!("並び替え対象のタスクが正しくありません")
    end

    def raise_invalid!(message)
      @project.errors.add(:base, message)
      raise ActiveRecord::RecordInvalid, @project
    end
  end
end
