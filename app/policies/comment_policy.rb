# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    owner_or_member? && record.task.project.archived_at.nil?
  end

  def update?
    author_membership_valid? &&
      record.task.project.archived_at.nil?
  end

  def destroy?
    update?
  end

  private

  def author_membership_valid?
    membership = record.team_membership

    user.present? &&
      membership.user_id == user.id &&
      membership.status == "active" &&
      %w[owner member].include?(membership.role)
  end
end
