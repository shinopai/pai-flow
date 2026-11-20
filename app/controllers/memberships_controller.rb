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

  def transfer_ownership
    authorize @team, :update?

    current_owner = @team.team_memberships.active.find_by!(user: current_user)
    new_owner = @team.team_memberships.find(ownership_params[:membership_id])

    Teams::TransferOwnershipService.call(
      team: @team,
      current_owner: current_owner,
      new_owner: new_owner
    )

    redirect_to team_members_path(@team), notice: "Owner権限を移譲しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to team_members_path(@team),
                alert: e.record.errors.full_messages.to_sentence
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

  def ownership_params
    params.expect(ownership: [:membership_id])
  end
end
