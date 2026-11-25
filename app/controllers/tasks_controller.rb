class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team
  before_action :set_project
  before_action :set_task, only: :update

  def create
    @task = @project.tasks.build
    authorize @task, :create?

    create_task
  end

  def update
    authorize @task, :update?

    update_task
  end

  private

  def create_task
    Tasks::CreateService.call(
      project: @project,
      user: current_user,
      attributes: task_params
    )

    redirect_to team_project_path(@team, @project),
                notice: "タスクを作成しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to team_project_path(@team, @project),
                alert: e.record.errors.full_messages.to_sentence
  end

  def update_task
    Tasks::UpdateService.call(
      task: @task,
      attributes: task_params
    )

    redirect_to team_project_path(@team, @project),
                notice: "タスクを更新しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to team_project_path(@team, @project),
                alert: e.record.errors.full_messages.to_sentence
  end

  def set_team
    @team = Team.find(params.expect(:team_id))
  end

  def set_project
    @project = @team.projects.find(params.expect(:project_id))
  end

  def set_task
    @task = @project.tasks.find(params.expect(:id))
  end

  def task_params
    params.expect(
      task: %i[
        title
        description
        due_date
        priority
        status
        assignee_membership_id
      ]
    )
  end
end
