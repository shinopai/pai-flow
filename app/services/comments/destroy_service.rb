# frozen_string_literal: true

module Comments
  class DestroyService
    def self.call(comment:, user:)
      new(comment:, user:).call
    end

    def initialize(comment:, user:)
      @comment = comment
      @user = user
    end

    def call
      @comment.task.project.with_lock do
        @comment.with_lock do
          validate_project_active!
          validate_membership!

          @comment.destroy!
        end
      end

      @comment
    end

    private

    def validate_project_active!
      return if @comment.task.project.archived_at.nil?

      @comment.errors.add(
        :base,
        "アーカイブ済みのプロジェクトのコメントは削除できません"
      )

      raise ActiveRecord::RecordInvalid, @comment
    end

    def validate_membership!
      membership = @comment.team_membership

      return if membership.user_id == @user.id &&
                membership.status == "active" &&
                %w[owner member].include?(membership.role)

      @comment.errors.add(
        :base,
        "コメントを削除できる権限がありません"
      )

      raise ActiveRecord::RecordInvalid, @comment
    end
  end
end
