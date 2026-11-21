class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation

    mail(
      to: @invitation.email,
      subject: "#{@invitation.team.name}への招待"
    )
  end
end
