# frozen_string_literal: true

class InvitationPolicy < ApplicationPolicy
  def show?
    invitee?
  end

  def accept?
    invitee?
  end

  def decline?
    invitee?
  end

  private

  def invitee?
    user.present? &&
      record.invitee_id == user.id &&
      record.email == user.email
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(invitee_id: user.id, email: user.email)
    end
  end
end
