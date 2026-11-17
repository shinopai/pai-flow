# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  private

  # 対象データが所属するチームを取得
  def team
    @team ||= case record
              when Team
                record
              when TeamMembership, Invitation, Project
                record.team
              when Task
                record.project.team
              when Comment
                record.task.project.team
              end
  end

  # ログインユーザーの有効なチーム所属を取得
  def active_membership
    return unless user && team

    if defined?(@active_membership)
      @active_membership
    else
      @active_membership = user.team_memberships.find_by(
        team_id: team.id,
        status: "active"
      )
    end
  end

  # 有効な所属があるか
  def active_member?
    active_membership.present?
  end

  # Ownerか
  def owner?
    active_membership&.role == "owner"
  end

  # OwnerまたはMemberか
  def owner_or_member?
    %w[owner member].include?(active_membership&.role)
  end

  # Guestか
  def guest?
    active_membership&.role == "guest"
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope

    # ログインユーザーの有効な所属チームID
    def active_team_ids
      return TeamMembership.none.select(:team_id) unless user

      user.team_memberships
          .where(status: "active")
          .select(:team_id)
    end
  end
end
