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
end
