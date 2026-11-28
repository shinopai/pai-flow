# frozen_string_literal: true

module Comments
  class CreateService
    def self.call(task:, user:, attributes:)
      new(
        task:,
        user:,
        attributes:
      ).call
    end

    def initialize(task:, user:, attributes:)
      @task = task
      @user = user
      @attributes = attributes.to_h.symbolize_keys.slice(:body)
    end

    def call
      comment = @task.comments.build(@attributes)

      ensure_project_active!(comment)

      membership = find_membership
      ensure_membership_valid!(comment, membership)

      comment.team_membership = membership
      comment.save!

      comment
    end

    private

    def ensure_project_active!(comment)
      return if @task.project.archived_at.nil?

      comment.errors.add(
        :base,
        "アーカイブ済みのプロジェクトにはコメントを投稿できません"
      )

      raise ActiveRecord::RecordInvalid, comment
    end

    def find_membership
      @user.team_memberships.find_by(
        team_id: @task.project.team_id,
        status: "active"
      )
    end

    def ensure_membership_valid!(comment, membership)
      return if membership && %w[owner member].include?(membership.role)

      comment.errors.add(
        :base,
        "コメントを投稿できる権限がありません"
      )

      raise ActiveRecord::RecordInvalid, comment
    end
  end
end
