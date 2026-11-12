module Invitations
  class AcceptService
    def self.call(invitation:, user:)
      new(invitation:, user:).call
    end

    def initialize(invitation:, user:)
      @invitation = invitation
      @user = user
    end

    def call
      Invitation.transaction do
        @invitation.lock!

        validate_invitation!

        accept_invitation!
        create_membership!
      end
    end

    private

    def validate_invitation!
      validate_pending!
      validate_invitee!
      validate_email!
      validate_not_member!

      raise ActiveRecord::RecordInvalid, @invitation if @invitation.errors.any?
    end

    def validate_pending!
      @invitation.errors.add(:status, "は承認できない状態です") if @invitation.status != "pending"
    end

    def validate_invitee!
      @invitation.errors.add(:invitee, "が一致しません") if @invitation.invitee_id != @user.id
    end

    def validate_email!
      @invitation.errors.add(:email, "が登録メールアドレスと一致しません") if @invitation.email != @user.email
    end

    def validate_not_member!
      return unless @invitation.team.team_memberships.exists?(
        user_id: @user.id,
        status: "active"
      )

      @invitation.errors.add(:invitee, "はすでにチームに所属しています")
    end

    def accept_invitation!
      @invitation.update!(
        status: "accepted",
        responded_at: Time.current
      )
    end

    def create_membership!
      @invitation.team.team_memberships.create!(
        user: @user,
        role: "guest",
        status: "active",
        joined_at: Time.current
      )
    end
  end
end
