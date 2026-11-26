# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Task destruction", type: :request do
  let!(:team) { create(:team) }
  let!(:owner) { create(:user, confirmed_at: Time.current) }
  let!(:owner_membership) do
    create(
      :team_membership,
      team: team,
      user: owner,
      role: "owner"
    )
  end

  let(:project) do
    create(
      :project,
      team: team,
      created_by: owner,
      assignee_membership: owner_membership
    )
  end

  let!(:task) do
    create(
      :task,
      project: project,
      created_by: owner,
      title: "削除対象のタスク"
    )
  end

  def sign_in(user)
    post user_session_path,
         params: {
           user: {
             email: user.email,
             password: "password123"
           }
         }
  end

  def delete_task(user, target_task = task)
    sign_in(user)

    delete team_project_task_path(team, project, target_task)
  end

  describe "DELETE /teams/:team_id/projects/:project_id/tasks/:id" do
    context "Ownerの場合" do
      it "タスクと配下のサブタスク・コメントを削除できる" do
        subtask = create(
          :task,
          project: project,
          created_by: owner,
          parent_task: task,
          title: "削除対象のサブタスク"
        )

        create(
          :comment,
          task: task,
          team_membership: owner_membership
        )
        create(
          :comment,
          task: subtask,
          team_membership: owner_membership
        )

        expect do
          delete_task(owner)
        end.to change(Task, :count).by(-2)
                                   .and change(Comment, :count).by(-2)

        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:notice]).to eq("タスクを削除しました。")
      end

      it "サブタスクとそのコメントだけを削除できる" do
        sibling = create(
          :task,
          project: project,
          created_by: owner,
          parent_task: task,
          title: "残すサブタスク"
        )

        subtask = create(
          :task,
          project: project,
          created_by: owner,
          parent_task: task,
          title: "削除対象のサブタスク"
        )

        parent_comment = create(
          :comment,
          task: task,
          team_membership: owner_membership
        )
        sibling_comment = create(
          :comment,
          task: sibling,
          team_membership: owner_membership
        )
        subtask_comment = create(
          :comment,
          task: subtask,
          team_membership: owner_membership
        )

        expect do
          delete_task(owner, subtask)
        end.to change(Task, :count).by(-1)
                                   .and change(Comment, :count).by(-1)

        expect(Task.exists?(task.id)).to be true
        expect(Task.exists?(sibling.id)).to be true
        expect(Comment.exists?(parent_comment.id)).to be true
        expect(Comment.exists?(sibling_comment.id)).to be true
        expect(Comment.exists?(subtask_comment.id)).to be false

        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:notice]).to eq("サブタスクを削除しました。")
      end
    end

    context "Memberの場合" do
      it "タスクを削除できる" do
        member = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: member,
          role: "member"
        )

        expect do
          delete_task(member)
        end.to change(Task, :count).by(-1)

        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:notice]).to eq("タスクを削除しました。")
      end
    end

    context "Guestの場合" do
      it "タスクを削除できず403を返す" do
        guest = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: guest,
          role: "guest"
        )

        expect do
          delete_task(guest)
        end.not_to change(Task, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "チームに所属していない場合" do
      it "タスクを削除できず403を返す" do
        user = create(:user, confirmed_at: Time.current)

        expect do
          delete_task(user)
        end.not_to change(Task, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      it "タスクを削除できず403を返す" do
        project.update!(archived_at: Time.current)

        expect do
          delete_task(owner)
        end.not_to change(Task, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "別プロジェクトのタスクを指定した場合" do
      it "タスクを削除できず404を返す" do
        another_project = create(
          :project,
          team: team,
          created_by: owner,
          assignee_membership: owner_membership
        )
        another_task = create(
          :task,
          project: another_project,
          created_by: owner
        )

        sign_in(owner)

        expect do
          delete team_project_task_path(team, project, another_task)
        end.not_to change(Task, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        expect do
          delete team_project_task_path(team, project, task)
        end.not_to change(Task, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
