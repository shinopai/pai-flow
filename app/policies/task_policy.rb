class TaskPolicy < ApplicationPolicy
  def create?
    owner_or_member? && record.project.archived_at.nil?
  end
end
