# frozen_string_literal: true

class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team, only: [:create]

  def create
    authorize @team, :update?

    Invitations::CreateService.call(
      team: @team,
      invited_by: current_user,
      email: invitation_params[:email]
    )

    redirect_to team_path(@team), notice: "招待メールを送信しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to team_path(@team),
                alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_team
    @team = Team.find(params.expect(:team_id))
  end

  def invitation_params
    params.expect(invitation: [:email])
  end
end
