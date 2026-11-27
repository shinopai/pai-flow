# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Task reorders", type: :request do
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

  let!(:task_a) do
    create(
      :task,
      project: project,
      created_by: owner,
      title: "タスクA",
      position: 0
    )
  end

  let!(:task_b) do
    create(
      :task,
      project: project,
      created_by: owner,
      title: "タスクB",
      position: 1
    )
  end

  let!(:task_c) do
    create(
      :task,
      project: project,
      created_by: owner,
      title: "タスクC",
      position: 2
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

  def submit_reorder(user, task_ids:, parent_task_id: nil)
    sign_in(user)

    patch team_project_reorder_tasks_path(team, project),
          params: {
            task_ids: task_ids,
            parent_task_id: parent_task_id
          }
  end

  def expect_task_positions(tasks)
    tasks.each_with_index do |task, index|
      expect(task.reload.position).to eq(index)
    end
  end

  describe "PATCH /teams/:team_id/projects/:project_id/tasks/reorder" do
    context "Ownerの場合" do
      it "通常タスクを指定順に並び替えできる" do
        submit_reorder(
          owner,
          task_ids: [task_c.id, task_a.id, task_b.id]
        )

        expect(response).to have_http_status(:no_content)
        expect_task_positions([task_c, task_a, task_b])
      end
    end

    context "Memberの場合" do
      it "通常タスクを指定順に並び替えできる" do
        member = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: member,
          role: "member"
        )

        submit_reorder(
          member,
          task_ids: [task_b.id, task_c.id, task_a.id]
        )

        expect(response).to have_http_status(:no_content)
        expect_task_positions([task_b, task_c, task_a])
      end
    end

    context "Guestの場合" do
      it "並び替えできず403を返す" do
        guest = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: guest,
          role: "guest"
        )

        expect do
          submit_reorder(
            guest,
            task_ids: [task_c.id, task_b.id, task_a.id]
          )
        end.not_to(change do
          [task_a.reload.position, task_b.reload.position, task_c.reload.position]
        end)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "チームに所属していない場合" do
      it "並び替えできず403を返す" do
        user = create(:user, confirmed_at: Time.current)

        submit_reorder(
          user,
          task_ids: [task_c.id, task_b.id, task_a.id]
        )

        expect(response).to have_http_status(:forbidden)
        expect_task_positions([task_a, task_b, task_c])
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      it "並び替えできず403を返す" do
        project.update!(archived_at: Time.current)

        submit_reorder(
          owner,
          task_ids: [task_c.id, task_b.id, task_a.id]
        )

        expect(response).to have_http_status(:forbidden)
        expect_task_positions([task_a, task_b, task_c])
      end
    end

    context "入力内容が不正な場合" do
      it "一部のタスクIDだけを送信した場合は422を返す" do
        submit_reorder(
          owner,
          task_ids: [task_a.id, task_b.id]
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to be_present
        expect_task_positions([task_a, task_b, task_c])
      end

      it "重複したタスクIDを送信した場合は422を返す" do
        submit_reorder(
          owner,
          task_ids: [task_a.id, task_a.id, task_c.id]
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to be_present
        expect_task_positions([task_a, task_b, task_c])
      end

      it "別プロジェクトのタスクIDを送信した場合は422を返す" do
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

        submit_reorder(
          owner,
          task_ids: [task_a.id, task_b.id, another_task.id]
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to be_present
        expect_task_positions([task_a, task_b, task_c])
      end
    end

    context "サブタスクの場合" do
      let!(:parent_task) do
        create(
          :task,
          project: project,
          created_by: owner,
          title: "親タスク"
        )
      end

      let!(:subtask_a) do
        create(
          :task,
          project: project,
          created_by: owner,
          parent_task: parent_task,
          title: "サブタスクA",
          position: 0
        )
      end

      let!(:subtask_b) do
        create(
          :task,
          project: project,
          created_by: owner,
          parent_task: parent_task,
          title: "サブタスクB",
          position: 1
        )
      end

      it "同じ親タスク内のサブタスクを並び替えできる" do
        submit_reorder(
          owner,
          parent_task_id: parent_task.id,
          task_ids: [subtask_b.id, subtask_a.id]
        )

        expect(response).to have_http_status(:no_content)
        expect_task_positions([subtask_b, subtask_a])
      end

      it "別の親タスクのサブタスクIDを含む場合は422を返す" do
        another_parent = create(
          :task,
          project: project,
          created_by: owner
        )
        another_subtask = create(
          :task,
          project: project,
          created_by: owner,
          parent_task: another_parent
        )

        submit_reorder(
          owner,
          parent_task_id: parent_task.id,
          task_ids: [subtask_a.id, another_subtask.id]
        )

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to be_present
        expect_task_positions([subtask_a, subtask_b])
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        patch team_project_reorder_tasks_path(team, project),
              params: {
                task_ids: [task_c.id, task_b.id, task_a.id]
              }

        expect(response).to redirect_to(new_user_session_path)
        expect_task_positions([task_a, task_b, task_c])
      end
    end
  end
end
