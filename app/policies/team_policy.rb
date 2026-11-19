# frozen_string_literal: true

class TeamPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    active_member?
  end

  def select?
    active_member?
  end

  def update?
    owner?
  end

  class Scope < Scope
    def resolve
      scope.where(id: active_team_ids)
    end
  end
end
