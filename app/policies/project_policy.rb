# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  def create?
    owner_or_member?
  end
end
