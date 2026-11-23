# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team

  def create
    prepare_project_for_creation
    create_project

    redirect_to team_project_path(@team, @project),
                notice: "プロジェクトを作成しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to team_path(@team),
                alert: e.record.errors.full_messages.to_sentence
  end

  def update
    find_project
    update_project

    redirect_to team_project_path(@team, @project),
                notice: "プロジェクトを更新しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to team_project_path(@team, @project),
                alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_team
    @team = Team.find(params.expect(:team_id))
  end

  def prepare_project_for_creation
    @project = @team.projects.build
    authorize @project, :create?
  end

  def create_project
    @project = Projects::CreateService.call(
      team: @team,
      user: current_user,
      **project_params
    )
  end

  def find_project
    @project = @team.projects.find(params.expect(:id))
    authorize @project, :update?
  end

  def update_project
    Projects::UpdateService.call(
      project: @project,
      attributes: project_update_params
    )
  end

  def project_params
    params.expect(
      project: %i[name description due_date]
    ).to_h.symbolize_keys
  end

  def project_update_params
    params.expect(
      project: %i[
        name
        description
        due_date
        status
        assignee_membership_id
      ]
    ).to_h.symbolize_keys
  end
end
