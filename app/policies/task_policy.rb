class TaskPolicy < ApplicationPolicy
  def create?
    owner_or_member? && record.project.archived_at.nil?
  end

  def update?
    owner_or_member? && record.project.archived_at.nil?
  end

  def destroy?
    owner_or_member? && record.project.archived_at.nil?
  end
end
