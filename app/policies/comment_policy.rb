# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    owner_or_member? && record.task.project.archived_at.nil?
  end
end
