# frozen_string_literal: true

class TeamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team, only: %i[select show edit update]

  def index
    authorize Team, :index?

    @teams = policy_scope(Team)

    head :ok
  end

  def select
    authorize @team, :select?

    current_user.update!(last_selected_team: @team)

    redirect_to team_path(@team)
  end

  def show
    authorize @team, :show?

    head :ok
  end

  def edit
    authorize @team, :edit?

    head :ok
  end

  def update
    authorize @team, :update?

    if @team.update(team_params)
      redirect_to team_path(@team), notice: "チーム名を変更しました。"
    else
      head :unprocessable_content
    end
  end

  private

  def set_team
    @team = Team.find(params.expect(:id))
  end

  def team_params
    params.expect(team: [:name])
  end
end
