# frozen_string_literal: true

class TeamsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize Team, :index?

    @teams = policy_scope(Team)

    head :ok
  end

  def select
    @team = Team.find(params.expect(:id))
    authorize @team, :select?

    current_user.update!(last_selected_team: @team)

    redirect_to team_path(@team)
  end

  def show
    @team = Team.find(params.expect(:id))
    authorize @team, :show?

    head :ok
  end

  def edit
    @team = Team.find(params.expect(:id))
    authorize @team, :edit?

    head :ok
  end

  def update
    @team = Team.find(params.expect(:id))
    authorize @team, :update?

    if @team.update(team_params)
      redirect_to team_path(@team), notice: "チーム名を変更しました。"
    else
      head :unprocessable_content
    end
  end

  private

  def team_params
    params.expect(team: [:name])
  end
end
