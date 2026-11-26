# frozen_string_literal: true

class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team, only: %i[index create destroy]
  before_action :set_invitation, only: %i[destroy]
  before_action :set_response_invitation, only: %i[accept decline]

  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

  def index
    authorize @team, :update?

    @invitations = @team.invitations
  end

  def create
    authorize @team, :update?

    Invitations::CreateService.call(
      team: @team,
      invited_by: current_user,
      email: invitation_params[:email]
    )

    redirect_to team_path(@team), notice: "招待メールを送信しました。"
  end

  def destroy
    authorize @team, :update?

    Invitations::CancelService.call(invitation: @invitation)

    redirect_to team_invitations_path(@team),
                notice: "招待を取り消しました。"
  end

  def accept
    authorize @invitation, :accept?

    Invitations::AcceptService.call(
      invitation: @invitation,
      user: current_user
    )

    redirect_to team_path(@invitation.team),
                notice: "チームへの招待を承諾しました。"
  end

  def decline
    authorize @invitation, :decline?

    Invitations::DeclineService.call(
      invitation: @invitation,
      user: current_user
    )

    redirect_to teams_path, notice: "チームへの招待を拒否しました。"
  end

  private

  def handle_record_invalid(exception)
    redirect_to record_invalid_redirect_path,
                alert: exception.record.errors.full_messages.to_sentence
  end

  def record_invalid_redirect_path
    case action_name
    when "create"
      team_path(@team)
    when "destroy"
      team_invitations_path(@team)
    when "accept", "decline"
      invitation_path(@invitation)
    end
  end

  def set_team
    @team = Team.find(params.expect(:team_id))
  end

  def set_invitation
    @invitation = @team.invitations.find(params.expect(:id))
  end

  def set_response_invitation
    @invitation = Invitation.find(params.expect(:id))
  end

  def invitation_params
    params.expect(invitation: [:email])
  end
end
