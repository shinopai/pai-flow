# frozen_string_literal: true

module Comments
  class UpdateService
    def self.call(comment:, user:, attributes:)
      new(
        comment:,
        user:,
        attributes:
      ).call
    end

    def initialize(comment:, user:, attributes:)
      @comment = comment
      @user = user
      @attributes = attributes.to_h.symbolize_keys.slice(:body)
    end

    def call
      @comment.task.project.with_lock do
        @comment.with_lock do
          validate_project_active!
          validate_membership!

          @comment.update!(@attributes)
        end
      end

      @comment
    end

    private

    def validate_project_active!
      return if @comment.task.project.archived_at.nil?

      @comment.errors.add(
        :base,
        "アーカイブ済みのプロジェクトのコメントは編集できません"
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
        "コメントを編集できる権限がありません"
      )

      raise ActiveRecord::RecordInvalid, @comment
    end
  end
end
