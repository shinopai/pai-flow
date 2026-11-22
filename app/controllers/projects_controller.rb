# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team

  def create
    @project = @team.projects.build
    authorize @project, :create?

    @project = Projects::CreateService.call(
      team: @team,
      user: current_user,
      **project_params
    )

    redirect_to team_project_path(@team, @project),
                notice: "プロジェクトを作成しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to team_path(@team),
                alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_team
    @team = Team.find(params.expect(:team_id))
  end

  def project_params
    params.expect(
      project: %i[name description due_date]
    ).to_h.symbolize_keys
  end
end
