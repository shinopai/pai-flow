# frozen_string_literal: true

class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team

  def index
    authorize @team, :show?

    @memberships = @team.team_memberships
                        .active
                        .includes(:user)
                        .order(:joined_at)

    head :ok
  end

  def update
    authorize @team, :update?

    @membership = @team.team_memberships.active.find(params.expect(:id))

    return head :unprocessable_content if @membership.role == "owner"

    return head :unprocessable_content unless %w[member guest].include?(member_params[:role])

    if @membership.update(member_params)
      redirect_to team_members_path(@team), notice: "メンバーの役割を変更しました。"
    else
      head :unprocessable_content
    end
  end

  def destroy
    authorize @team, :show?

    @membership = @team.team_memberships.active.find_by!(user: current_user)

    Teams::LeaveService.call(team_membership: @membership)

    redirect_to teams_path, notice: "チームから退出しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to team_members_path(@team), alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_team
    @team = Team.find(params.expect(:team_id))
  end

  def member_params
    params.expect(member: [:role])
  end
end
