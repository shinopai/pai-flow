# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tasks", type: :request do
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

  let(:expected_task_attributes) do
    {
      project: project,
      title: "新規タスク",
      description: "タスクの説明",
      due_date: Date.new(2026, 12, 31),
      priority: "high",
      status: "in_progress",
      parent_task_id: nil,
      position: 1
    }
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

  def submit_task(user, attributes)
    sign_in(user)

    post team_project_tasks_path(team, project),
         params: { task: attributes }
  end

  def expect_created_task(user)
    expect(Task.last).to have_attributes(
      expected_task_attributes.merge(created_by: user)
    )
  end

  describe "POST /teams/:team_id/projects/:project_id/tasks" do
    context "Ownerの場合" do
      it "タスクを作成できる" do
        expect do
          submit_task(
            owner,
            {
              title: "新規タスク",
              description: "タスクの説明",
              due_date: "2026-12-31",
              priority: "high",
              status: "in_progress"
            }
          )
        end.to change(Task, :count).by(1)

        expect_created_task(owner)
        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:notice]).to eq("タスクを作成しました。")
      end
    end

    context "Memberの場合" do
      it "タスクを作成できる" do
        member = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: member,
          role: "member"
        )

        expect do
          submit_task(
            member,
            {
              title: "新規タスク",
              description: "タスクの説明",
              due_date: "2026-12-31",
              priority: "high",
              status: "in_progress"
            }
          )
        end.to change(Task, :count).by(1)

        expect_created_task(member)
        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:notice]).to eq("タスクを作成しました。")
      end
    end

    context "優先度とステータスを指定しない場合" do
      it "初期値を設定してタスクを作成する" do
        expect do
          submit_task(owner, { title: "新規タスク" })
        end.to change(Task, :count).by(1)

        task = Task.last

        expect(task.priority).to eq("medium")
        expect(task.status).to eq("not_started")
        expect(response).to redirect_to(
          team_project_path(team, project)
        )
      end
    end

    context "Guestの場合" do
      it "タスクを作成できず403を返す" do
        guest = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: guest,
          role: "guest"
        )

        expect do
          submit_task(guest, { title: "新規タスク" })
        end.not_to change(Task, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "チームに所属していない場合" do
      it "タスクを作成できず403を返す" do
        user = create(:user, confirmed_at: Time.current)

        expect do
          submit_task(user, { title: "新規タスク" })
        end.not_to change(Task, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "入力内容が不正な場合" do
      it "タイトルが空の場合は作成せずエラーを返す" do
        expect do
          submit_task(owner, { title: "" })
        end.not_to change(Task, :count)

        expect(response).to redirect_to(
          team_project_path(team, project)
        )
        expect(flash[:alert]).to be_present
      end

      it "タイトルが未送信の場合は作成せずエラーを返す" do
        expect do
          submit_task(owner, { description: "タスクの説明" })
        end.not_to change(Task, :count)

        expect(response).to redirect_to(
          team_project_path(team, project)
        )
        expect(flash[:alert]).to be_present
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      it "タスクを作成できず403を返す" do
        project.update!(archived_at: Time.current)

        expect do
          submit_task(owner, { title: "新規タスク" })
        end.not_to change(Task, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "別チームのプロジェクトを指定した場合" do
      it "タスクを作成できず404を返す" do
        another_team = create(:team)
        another_project = create(
          :project,
          team: another_team,
          created_by: owner
        )

        sign_in(owner)

        expect do
          post team_project_tasks_path(team, another_project),
               params: {
                 task: {
                   title: "新規タスク"
                 }
               }
        end.not_to change(Task, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        expect do
          post team_project_tasks_path(team, project),
               params: {
                 task: {
                   title: "新規タスク"
                 }
               }
        end.not_to change(Task, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /teams/:team_id/projects/:project_id/tasks/:id" do
    let!(:task) do
      create(
        :task,
        project: project,
        created_by: owner,
        title: "更新前のタスク"
      )
    end

    def submit_task_update(user, attributes, target_task = task)
      sign_in(user)

      patch team_project_task_path(team, project, target_task),
            params: { task: attributes }
    end

    context "Ownerの場合" do
      it "タスクを更新できる" do
        submit_task_update(
          owner,
          {
            title: "更新後のタスク",
            description: "更新後の説明",
            due_date: "2027-01-31",
            priority: "high",
            status: "in_progress"
          }
        )

        expect(task.reload).to have_attributes(
          title: "更新後のタスク",
          description: "更新後の説明",
          due_date: Date.new(2027, 1, 31),
          priority: "high",
          status: "in_progress"
        )
        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:notice]).to eq("タスクを更新しました。")
      end
    end

    context "Memberの場合" do
      it "タスクを更新できる" do
        member = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: member,
          role: "member"
        )

        submit_task_update(
          member,
          { title: "Memberによる更新" }
        )

        expect(task.reload.title).to eq("Memberによる更新")
        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:notice]).to eq("タスクを更新しました。")
      end
    end

    context "Guestの場合" do
      it "タスクを更新できず403を返す" do
        guest = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: guest,
          role: "guest"
        )
        original_title = task.title

        submit_task_update(
          guest,
          { title: "Guestによる更新" }
        )

        expect(response).to have_http_status(:forbidden)
        expect(task.reload.title).to eq(original_title)
      end
    end

    context "チームに所属していない場合" do
      it "タスクを更新できず403を返す" do
        user = create(:user, confirmed_at: Time.current)
        original_title = task.title

        submit_task_update(
          user,
          { title: "未所属ユーザーによる更新" }
        )

        expect(response).to have_http_status(:forbidden)
        expect(task.reload.title).to eq(original_title)
      end
    end

    context "入力内容が不正な場合" do
      it "タイトルが空の場合は更新せずエラーを返す" do
        original_title = task.title

        submit_task_update(
          owner,
          { title: "" }
        )

        expect(response).to redirect_to(
          team_project_path(team, project)
        )
        expect(flash[:alert]).to be_present
        expect(task.reload.title).to eq(original_title)
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      it "タスクを更新できず403を返す" do
        project.update!(archived_at: Time.current)
        original_title = task.title

        submit_task_update(
          owner,
          { title: "アーカイブ後の更新" }
        )

        expect(response).to have_http_status(:forbidden)
        expect(task.reload.title).to eq(original_title)
      end
    end

    context "別プロジェクトのタスクを指定した場合" do
      it "タスクを更新できず404を返す" do
        another_project = create(
          :project,
          team: team,
          created_by: owner,
          assignee_membership: owner_membership
        )
        another_task = create(
          :task,
          project: another_project,
          created_by: owner,
          title: "別プロジェクトのタスク"
        )

        original_title = another_task.title

        sign_in(owner)

        patch team_project_task_path(team, project, another_task),
              params: {
                task: {
                  title: "不正な更新"
                }
              }

        expect(response).to have_http_status(:not_found)
        expect(another_task.reload.title).to eq(original_title)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        patch team_project_task_path(team, project, task),
              params: {
                task: {
                  title: "未ログインでの更新"
                }
              }

        expect(response).to redirect_to(new_user_session_path)
        expect(task.reload.title).to eq("更新前のタスク")
      end
    end

    context "サブタスクの場合" do
      it "サブタスクを更新できる" do
        parent_task = create(
          :task,
          project: project,
          created_by: owner
        )
        subtask = create(
          :task,
          project: project,
          created_by: owner,
          parent_task: parent_task,
          title: "更新前のサブタスク"
        )

        submit_task_update(
          owner,
          { title: "更新後のサブタスク" },
          subtask
        )

        expect(subtask.reload.title).to eq("更新後のサブタスク")
        expect(subtask.parent_task).to eq(parent_task)
        expect(response).to redirect_to(team_project_path(team, project))
      end
    end
  end
end
