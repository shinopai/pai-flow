# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  def create?
    owner_or_member?
  end

  def update?
    owner_or_member? && record.archived_at.nil?
  end
end
