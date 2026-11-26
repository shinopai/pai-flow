# frozen_string_literal: true

class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team

  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

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

    membership = @team.team_memberships.active.find(params.expect(:id))
    attributes = member_params

    return head :unprocessable_content if membership.role == "owner"
    return head :unprocessable_content unless %w[member guest].include?(attributes[:role])

    if membership.update(attributes)
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
  end

  def destroy
    authorize @team, :show?

    membership = @team.team_memberships.active.find_by!(user: current_user)

    Teams::LeaveService.call(team_membership: membership)

    redirect_to teams_path, notice: "チームから退出しました。"
  end

  private

  def handle_record_invalid(exception)
    redirect_to team_members_path(@team),
                alert: exception.record.errors.full_messages.to_sentence
  end

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
