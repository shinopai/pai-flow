# frozen_string_literal: true

module Tasks
  class DestroyService
    def self.call(task:)
      new(task:).call
    end

    def initialize(task:)
      @task = task
    end

    def call
      @task.project.with_lock do
        @task.with_lock do
          validate_project_active!
          @task.destroy!
        end
      end

      @task
    end

    private

    def validate_project_active!
      return if @task.project.archived_at.nil?

      @task.errors.add(
        :base,
        "アーカイブ済みのプロジェクトのタスクは削除できません"
      )
      raise ActiveRecord::RecordInvalid, @task
    end
  end
end
