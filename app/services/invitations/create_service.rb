module Invitations
  class CreateService
    def self.call(team:, invited_by:, email:)
      new(team:, invited_by:, email:).call
    end

    def initialize(team:, invited_by:, email:)
      @team = team
      @invited_by = invited_by
      @email = email.to_s.strip.downcase
    end

    def call
      validate_inviter!

      invitation = build_invitation

      validate_invitee!(invitation)
      validate_not_member!(invitation)

      save_and_send(invitation)

      invitation
    end

    private

    def validate_inviter!
      return if @team.team_memberships.exists?(
        user: @invited_by,
        role: "owner",
        status: "active"
      )

      raise Pundit::NotAuthorizedError
    end

    def validate_invitee!(invitation)
      return if invitation.invitee.present?

      invitation.errors.add(:email, "に該当する登録済みユーザーがいません")
      raise ActiveRecord::RecordInvalid, invitation
    end

    def validate_not_member!(invitation)
      return unless @team.team_memberships.exists?(
        user: invitation.invitee,
        status: "active"
      )

      invitation.errors.add(:email, "のユーザーはすでにチームに所属しています")
      raise ActiveRecord::RecordInvalid, invitation
    end

    def build_invitation
      @team.invitations.new(
        invitee: User.find_by(email: @email),
        invited_by: @invited_by,
        email: @email,
        status: "pending"
      )
    end

    def save_and_send(invitation)
      invitation.save!

      InvitationMailer.invite(invitation).deliver_now
    end
  end
end
