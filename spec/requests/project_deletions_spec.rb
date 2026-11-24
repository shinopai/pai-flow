# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project deletions", type: :request do
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

  let!(:project) do
    create(
      :project,
      team: team,
      created_by: owner,
      assignee_membership: owner_membership
    )
  end

  let!(:task) { create(:task, project: project) }
  let!(:subtask) do
    create(:task, project: project, parent_task_id: task.id)
  end
  let!(:task_comment) do
    create(:comment, task: task, team_membership: owner_membership)
  end
  let!(:subtask_comment) do
    create(:comment, task: subtask, team_membership: owner_membership)
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

  describe "DELETE /teams/:team_id/projects/:id" do
    context "Owner・Memberの場合" do
      %w[owner member].each do |role|
        it "#{role}はプロジェクトと関連データを完全削除できる" do
          user = if role == "owner"
                   owner
                 else
                   member = create(:user, confirmed_at: Time.current)
                   create(
                     :team_membership,
                     team: team,
                     user: member,
                     role: "member"
                   )
                   member
                 end

          sign_in(user)

          expect do
            delete team_project_path(team, project)
          end.to change(Project, :count).by(-1)
                                        .and change(Task, :count).by(-2)
                                                                 .and change(Comment, :count).by(-2)

          expect(response).to redirect_to(team_path(team))
          expect(flash[:notice]).to eq("プロジェクトを削除しました。")
        end
      end
    end

    context "アーカイブ済みの場合" do
      it "Ownerはプロジェクトを完全削除できる" do
        project.update!(archived_at: Time.current)

        sign_in(owner)

        expect do
          delete team_project_path(team, project)
        end.to change(Project, :count).by(-1)

        expect(response).to redirect_to(team_path(team))
        expect(Project.exists?(project.id)).to be false
      end
    end

    context "Guestの場合" do
      it "プロジェクトを削除できず403を返す" do
        guest = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: guest,
          role: "guest"
        )

        sign_in(guest)

        expect do
          delete team_project_path(team, project)
        end.not_to change(Project, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "チームに所属していない場合" do
      it "プロジェクトを削除できず403を返す" do
        user = create(:user, confirmed_at: Time.current)

        sign_in(user)

        expect do
          delete team_project_path(team, project)
        end.not_to change(Project, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "別チームのプロジェクトを指定した場合" do
      it "プロジェクトを取得できず404を返す" do
        another_team = create(:team)
        another_project = create(
          :project,
          team: another_team,
          created_by: owner
        )

        sign_in(owner)

        expect do
          delete team_project_path(team, another_project)
        end.not_to change(Project, :count)

        expect(response).to have_http_status(:not_found)
        expect(Project.exists?(another_project.id)).to be true
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        expect do
          delete team_project_path(team, project)
        end.not_to change(Project, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
