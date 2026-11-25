# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team

  def index
    authorize @team, :show?

    @search_conditions = project_search_params
    projects = Projects::ListService.call(
      team: @team,
      filters: @search_conditions
    )

    @total_count = projects.count
    @current_page = normalized_page
    @per_page = Projects::ListService::PER_PAGE
    @total_pages = (@total_count.to_f / @per_page).ceil

    @projects = projects
                .limit(@per_page)
                .offset((@current_page - 1) * @per_page)

    head :ok
  rescue Projects::ListService::InvalidDateRange => e
    @search_error = e.message
    @projects = @team.projects.none

    head :unprocessable_content
  end

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
    authorize @project, :update?
    update_project

    redirect_to team_project_path(@team, @project),
                notice: "プロジェクトを更新しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to team_project_path(@team, @project),
                alert: e.record.errors.full_messages.to_sentence
  end

  def archive
    find_project
    authorize @project, :archive?
    Projects::ArchiveService.call(project: @project)

    redirect_to team_path(@team),
                notice: "プロジェクトをアーカイブしました。"
  end

  def restore
    find_project
    authorize @project, :restore?
    Projects::RestoreService.call(project: @project)

    redirect_to team_project_path(@team, @project),
                notice: "プロジェクトを復元しました。"
  end

  def destroy
    find_project
    authorize @project, :destroy?
    Projects::DestroyService.call(project: @project)

    redirect_to team_path(@team),
                notice: "プロジェクトを削除しました。"
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

  def project_search_params
    params.permit(
      :keyword,
      :status,
      :assignee_id,
      :due_date_from,
      :due_date_to,
      :sort
    ).to_h.symbolize_keys
  end

  def normalized_page
    page = params[:page].to_s
    return 1 unless page.match?(/\A\d+\z/)

    [page.to_i, 1].max
  end
end
