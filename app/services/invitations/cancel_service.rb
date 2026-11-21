# frozen_string_literal: true

module Invitations
  class CancelService
    def self.call(invitation:)
      new(invitation:).call
    end

    def initialize(invitation:)
      @invitation = invitation
    end

    def call
      Invitation.transaction do
        @invitation.lock!

        validate_pending!

        @invitation.update!(
          status: "cancelled",
          responded_at: Time.current
        )
      end
    end

    private

    def validate_pending!
      return if @invitation.status == "pending"

      @invitation.errors.add(:status, "は取消できない状態です")
      raise ActiveRecord::RecordInvalid, @invitation
    end
  end
end
