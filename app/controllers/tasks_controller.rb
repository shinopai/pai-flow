class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team
  before_action :set_project
  before_action :set_task, only: %i[update destroy]
  before_action :set_parent_task, only: :create_subtask

  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

  def create
    task = @project.tasks.build
    authorize task, :create?

    Tasks::CreateService.call(
      project: @project,
      user: current_user,
      attributes: task_params
    )

    redirect_to team_project_path(@team, @project),
                notice: "タスクを作成しました。"
  end

  def create_subtask
    subtask = @project.tasks.build(parent_task: @parent_task)
    authorize subtask, :create?

    Tasks::CreateService.call(
      project: @project,
      user: current_user,
      parent_task: @parent_task,
      attributes: task_params
    )

    redirect_to team_project_path(@team, @project),
                notice: "サブタスクを作成しました。"
  end

  def update
    authorize @task, :update?

    Tasks::UpdateService.call(
      task: @task,
      attributes: task_params
    )

    redirect_to team_project_path(@team, @project),
                notice: "タスクを更新しました。"
  end

  def destroy
    authorize @task, :destroy?

    is_subtask = @task.parent_task_id.present?

    Tasks::DestroyService.call(task: @task)

    notice = if is_subtask
               "サブタスクを削除しました。"
             else
               "タスクを削除しました。"
             end

    redirect_to team_project_path(@team, @project),
                notice: notice
  end

  def reorder
    authorize @project, :reorder?

    Tasks::ReorderService.call(
      project: @project,
      task_ids: params[:task_ids],
      parent_task_id: params[:parent_task_id]
    )

    head :no_content
  end

  private

  def handle_record_invalid(exception)
    if action_name == "reorder"
      render json: {
        errors: exception.record.errors.full_messages
      }, status: :unprocessable_content
    else
      redirect_to team_project_path(@team, @project),
                  alert: exception.record.errors.full_messages.to_sentence
    end
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

  def set_parent_task
    @parent_task = @project.tasks
                           .where(parent_task_id: nil)
                           .find(params.expect(:id))
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
