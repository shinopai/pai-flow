# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team
  before_action :set_project
  before_action :set_task
  before_action :set_comment, only: %i[update destroy]

  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

  def create
    @comment = @task.comments.build
    authorize @comment, :create?

    Comments::CreateService.call(
      task: @task,
      user: current_user,
      attributes: comment_params
    )

    redirect_to team_project_path(@team, @project),
                notice: "コメントを投稿しました。"
  end

  def update
    authorize @comment, :update?

    Comments::UpdateService.call(
      comment: @comment,
      user: current_user,
      attributes: comment_params
    )

    redirect_to team_project_path(@team, @project),
                notice: "コメントを更新しました。"
  end

  def destroy
    authorize @comment, :destroy?

    Comments::DestroyService.call(
      comment: @comment,
      user: current_user
    )

    redirect_to team_project_path(@team, @project),
                notice: "コメントを削除しました。"
  end

  private

  def set_team
    @team = Team.find(params.expect(:team_id))
  end

  def set_project
    @project = @team.projects.find(params.expect(:project_id))
  end

  def set_task
    @task = @project.tasks.find(params.expect(:task_id))
  end

  def set_comment
    @comment = @task.comments.find(params.expect(:id))
  end

  def comment_params
    params.expect(comment: [:body])
  end

  def handle_record_invalid(exception)
    redirect_to team_project_path(@team, @project),
                alert: exception.record.errors.full_messages.to_sentence
  end
end
