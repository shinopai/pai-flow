# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::CreateService do
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team) }
  let(:user) { create(:user) }

  describe ".call" do
    context "有効な属性の場合" do
      it "タスクを作成し、作成者を設定する" do
        task = described_class.call(
          project: project,
          user: user,
          attributes: {
            title: "新規タスク",
            description: "タスクの説明",
            due_date: Date.new(2026, 12, 31),
            priority: "high",
            status: "in_progress"
          }
        )

        expect(task).to be_persisted
        expect(task.project).to eq(project)
        expect(task.created_by).to eq(user)
        expect(task.title).to eq("新規タスク")
        expect(task.description).to eq("タスクの説明")
        expect(task.due_date).to eq(Date.new(2026, 12, 31))
        expect(task.priority).to eq("high")
        expect(task.status).to eq("in_progress")
        expect(task.parent_task_id).to be_nil
      end
    end

    context "優先度とステータスを指定しない場合" do
      it "初期値を設定する" do
        task = described_class.call(
          project: project,
          user: user,
          attributes: { title: "新規タスク" }
        )

        expect(task.priority).to eq("medium")
        expect(task.status).to eq("not_started")
      end
    end

    context "担当者を指定した場合" do
      it "同じチームの有効なOwnerを担当者に設定する" do
        membership = create(
          :team_membership,
          team: team,
          role: "owner"
        )

        task = described_class.call(
          project: project,
          user: user,
          attributes: {
            title: "新規タスク",
            assignee_membership_id: membership.id
          }
        )

        expect(task.assignee_membership).to eq(membership)
      end
    end

    context "Guestを担当者に指定した場合" do
      it "タスクを作成せず、エラーを返す" do
        membership = create(
          :team_membership,
          team: team,
          role: "guest"
        )

        expect do
          described_class.call(
            project: project,
            user: user,
            attributes: {
              title: "新規タスク",
              assignee_membership_id: membership.id
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.tasks.count).to eq(0)
      end
    end

    context "離脱済みのメンバーを担当者に指定した場合" do
      it "タスクを作成せず、エラーを返す" do
        membership = create(
          :team_membership,
          team: team,
          role: "member",
          status: "left",
          left_at: Time.current
        )

        expect do
          described_class.call(
            project: project,
            user: user,
            attributes: {
              title: "新規タスク",
              assignee_membership_id: membership.id
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.tasks.count).to eq(0)
      end
    end

    context "別チームのメンバーを担当者に指定した場合" do
      it "タスクを作成せず、エラーを返す" do
        another_team = create(:team)
        membership = create(
          :team_membership,
          team: another_team,
          role: "member"
        )

        expect do
          described_class.call(
            project: project,
            user: user,
            attributes: {
              title: "新規タスク",
              assignee_membership_id: membership.id
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.tasks.count).to eq(0)
      end
    end

    context "タスクを複数作成する場合" do
      it "通常タスクのpositionを順番に設定する" do
        first_task = create(
          :task,
          project: project,
          position: 1
        )

        second_task = described_class.call(
          project: project,
          user: user,
          attributes: { title: "2番目のタスク" }
        )

        third_task = described_class.call(
          project: project,
          user: user,
          attributes: { title: "3番目のタスク" }
        )

        expect(first_task.position).to eq(1)
        expect(second_task.position).to eq(2)
        expect(third_task.position).to eq(3)
      end
    end

    context "サブタスクが存在する場合" do
      it "サブタスクのpositionを通常タスクの順序に含めない" do
        parent_task = create(
          :task,
          project: project,
          position: 1
        )

        create(
          :task,
          project: project,
          parent_task: parent_task,
          position: 100
        )

        task = described_class.call(
          project: project,
          user: user,
          attributes: { title: "新規タスク" }
        )

        expect(task.position).to eq(2)
      end
    end

    context "親タスクを指定した場合" do
      let(:parent_task) do
        create(:task, project: project, position: 1)
      end

      it "親タスクに紐づくサブタスクを作成する" do
        subtask = described_class.call(
          project: project,
          user: user,
          parent_task: parent_task,
          attributes: { title: "新規サブタスク" }
        )

        expect(subtask).to be_persisted
        expect(subtask.project).to eq(project)
        expect(subtask.parent_task).to eq(parent_task)
        expect(subtask.created_by).to eq(user)
        expect(subtask.title).to eq("新規サブタスク")
      end

      it "優先度とステータスの初期値を設定する" do
        subtask = described_class.call(
          project: project,
          user: user,
          parent_task: parent_task,
          attributes: { title: "新規サブタスク" }
        )

        expect(subtask.priority).to eq("medium")
        expect(subtask.status).to eq("not_started")
      end

      it "同じ親タスク内でpositionを順番に設定する" do
        first_subtask = create(
          :task,
          project: project,
          parent_task: parent_task,
          position: 1
        )

        second_subtask = described_class.call(
          project: project,
          user: user,
          parent_task: parent_task,
          attributes: { title: "2番目のサブタスク" }
        )

        third_subtask = described_class.call(
          project: project,
          user: user,
          parent_task: parent_task,
          attributes: { title: "3番目のサブタスク" }
        )

        expect(first_subtask.position).to eq(1)
        expect(second_subtask.position).to eq(2)
        expect(third_subtask.position).to eq(3)
      end

      it "親タスクごとにpositionを独立して採番する" do
        another_parent_task = create(
          :task,
          project: project,
          position: 2
        )

        create(
          :task,
          project: project,
          parent_task: another_parent_task,
          position: 5
        )

        subtask = described_class.call(
          project: project,
          user: user,
          parent_task: parent_task,
          attributes: { title: "新規サブタスク" }
        )

        expect(subtask.position).to eq(1)
      end

      it "別プロジェクトのタスクを親に指定した場合は作成しない" do
        another_project = create(:project, team: team)
        another_parent_task = create(
          :task,
          project: another_project
        )

        expect do
          described_class.call(
            project: project,
            user: user,
            parent_task: another_parent_task,
            attributes: { title: "新規サブタスク" }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.tasks.count).to eq(0)
      end

      it "サブタスクを親に指定した場合は作成しない" do
        existing_subtask = create(
          :task,
          project: project,
          parent_task: parent_task
        )

        expect do
          described_class.call(
            project: project,
            user: user,
            parent_task: existing_subtask,
            attributes: { title: "階層外サブタスク" }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.tasks.count).to eq(2)
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      before do
        project.update!(archived_at: Time.current)
      end

      it "タスクを作成せず、エラーを返す" do
        expect do
          described_class.call(
            project: project,
            user: user,
            attributes: { title: "新規タスク" }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.tasks.count).to eq(0)
      end
    end

    context "タイトルが空の場合" do
      it "タスクを作成せず、エラーを返す" do
        expect do
          described_class.call(
            project: project,
            user: user,
            attributes: { title: "" }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.tasks.count).to eq(0)
      end
    end
  end
end
