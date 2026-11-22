# frozen_string_literal: true

module Invitations
  class DeclineService
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

        decline_invitation!
      end
    end

    private

    def validate_invitation!
      validate_pending!
      validate_invitee!
      validate_email!

      raise ActiveRecord::RecordInvalid, @invitation if @invitation.errors.any?
    end

    def validate_pending!
      @invitation.errors.add(:status, "は拒否できない状態です") if @invitation.status != "pending"
    end

    def validate_invitee!
      @invitation.errors.add(:invitee, "が一致しません") if @invitation.invitee_id != @user.id
    end

    def validate_email!
      @invitation.errors.add(:email, "が登録メールアドレスと一致しません") if @invitation.email != @user.email
    end

    def decline_invitation!
      @invitation.update!(
        status: "declined",
        responded_at: Time.current
      )
    end
  end
end
