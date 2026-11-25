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
