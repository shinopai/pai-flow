# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::UpdateService do
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team) }
  let(:task) { create(:task, project: project) }

  describe ".call" do
    context "有効な属性の場合" do
      it "タスクの情報を更新する" do
        described_class.call(
          task: task,
          attributes: {
            title: "更新後のタスク",
            description: "更新後の説明",
            due_date: Date.new(2027, 1, 31),
            priority: "high",
            status: "in_progress"
          }
        )

        expect(task.reload.title).to eq("更新後のタスク")
        expect(task.description).to eq("更新後の説明")
        expect(task.due_date).to eq(Date.new(2027, 1, 31))
        expect(task.priority).to eq("high")
        expect(task.status).to eq("in_progress")
      end

      it "完了済みタスクを未完了のステータスに戻せる" do
        task.update!(status: "completed")

        described_class.call(
          task: task,
          attributes: {
            status: "in_progress"
          }
        )

        expect(task.reload.status).to eq("in_progress")
      end
    end

    context "担当者を指定した場合" do
      it "同じチームの有効なOwnerを担当者に設定する" do
        membership = create(
          :team_membership,
          team: team,
          role: "owner"
        )

        described_class.call(
          task: task,
          attributes: {
            assignee_membership_id: membership.id
          }
        )

        expect(task.reload.assignee_membership).to eq(membership)
      end

      it "同じチームの有効なMemberを担当者に設定する" do
        membership = create(
          :team_membership,
          team: team,
          role: "member"
        )

        described_class.call(
          task: task,
          attributes: {
            assignee_membership_id: membership.id
          }
        )

        expect(task.reload.assignee_membership).to eq(membership)
      end

      it "設定済みの担当者を別のMemberに変更する" do
        original_membership = create(
          :team_membership,
          team: team,
          role: "member"
        )
        new_membership = create(
          :team_membership,
          team: team,
          role: "member"
        )
        task.update!(assignee_membership: original_membership)

        described_class.call(
          task: task,
          attributes: {
            assignee_membership_id: new_membership.id
          }
        )

        expect(task.reload.assignee_membership).to eq(new_membership)
      end
    end

    context "担当者を空欄にした場合" do
      it "担当者を解除する" do
        membership = create(
          :team_membership,
          team: team,
          role: "member"
        )
        task.update!(assignee_membership: membership)

        described_class.call(
          task: task,
          attributes: {
            assignee_membership_id: ""
          }
        )

        expect(task.reload.assignee_membership).to be_nil
      end
    end

    context "担当者を指定しない場合" do
      it "現在の担当者を維持する" do
        membership = create(
          :team_membership,
          team: team,
          role: "member"
        )
        task.update!(assignee_membership: membership)

        described_class.call(
          task: task,
          attributes: {
            title: "更新後のタスク"
          }
        )

        expect(task.reload.assignee_membership).to eq(membership)
      end
    end

    context "Guestを担当者に指定した場合" do
      it "タスクを更新せず、エラーを返す" do
        membership = create(
          :team_membership,
          team: team,
          role: "guest"
        )
        original_title = task.title

        expect do
          described_class.call(
            task: task,
            attributes: {
              title: "更新後のタスク",
              assignee_membership_id: membership.id
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(task.reload.title).to eq(original_title)
      end
    end

    context "離脱済みのメンバーを担当者に指定した場合" do
      it "タスクを更新せず、エラーを返す" do
        membership = create(
          :team_membership,
          team: team,
          role: "member",
          status: "left",
          left_at: Time.current
        )
        original_title = task.title

        expect do
          described_class.call(
            task: task,
            attributes: {
              title: "更新後のタスク",
              assignee_membership_id: membership.id
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(task.reload.title).to eq(original_title)
      end
    end

    context "別チームのメンバーを担当者に指定した場合" do
      it "タスクを更新せず、エラーを返す" do
        another_team = create(:team)
        membership = create(
          :team_membership,
          team: another_team,
          role: "member"
        )
        original_title = task.title

        expect do
          described_class.call(
            task: task,
            attributes: {
              title: "更新後のタスク",
              assignee_membership_id: membership.id
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(task.reload.title).to eq(original_title)
      end
    end

    context "期限を空欄にした場合" do
      it "期限を解除する" do
        task.update!(due_date: Date.new(2026, 12, 31))

        described_class.call(
          task: task,
          attributes: {
            due_date: ""
          }
        )

        expect(task.reload.due_date).to be_nil
      end
    end

    context "期限を指定しない場合" do
      it "現在の期限を維持する" do
        due_date = Date.new(2026, 12, 31)
        task.update!(due_date: due_date)

        described_class.call(
          task: task,
          attributes: {
            title: "更新後のタスク"
          }
        )

        expect(task.reload.due_date).to eq(due_date)
      end
    end

    context "不正な属性の場合" do
      it "タスクを更新せず、エラーを返す" do
        original_title = task.title

        expect do
          described_class.call(
            task: task,
            attributes: {
              title: "",
              status: "invalid"
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(task.reload.title).to eq(original_title)
      end
    end

    context "positionなど編集対象外の属性を指定した場合" do
      it "編集対象外の属性を変更しない" do
        original_position = task.position
        original_parent_task_id = task.parent_task_id

        described_class.call(
          task: task,
          attributes: {
            title: "更新後のタスク",
            position: 99,
            parent_task_id: 999
          }
        )

        expect(task.reload.title).to eq("更新後のタスク")
        expect(task.position).to eq(original_position)
        expect(task.parent_task_id).to eq(original_parent_task_id)
      end
    end

    context "サブタスクの場合" do
      it "サブタスクの情報を更新する" do
        parent_task = create(:task, project: project)
        subtask = create(
          :task,
          project: project,
          parent_task: parent_task
        )

        described_class.call(
          task: subtask,
          attributes: {
            title: "更新後のサブタスク"
          }
        )

        expect(subtask.reload.title).to eq("更新後のサブタスク")
        expect(subtask.parent_task).to eq(parent_task)
      end

      it "サブタスクに担当者を設定する" do
        parent_task = create(:task, project: project)
        subtask = create(
          :task,
          project: project,
          parent_task: parent_task
        )
        membership = create(
          :team_membership,
          team: team,
          role: "member"
        )

        described_class.call(
          task: subtask,
          attributes: {
            assignee_membership_id: membership.id
          }
        )

        expect(subtask.reload.assignee_membership).to eq(membership)
      end

      it "サブタスクの期限を変更する" do
        parent_task = create(:task, project: project)
        subtask = create(
          :task,
          project: project,
          parent_task: parent_task
        )
        due_date = Date.new(2027, 2, 28)

        described_class.call(
          task: subtask,
          attributes: {
            due_date: due_date
          }
        )

        expect(subtask.reload.due_date).to eq(due_date)
      end

      it "サブタスクのステータスを変更する" do
        parent_task = create(:task, project: project)
        subtask = create(
          :task,
          project: project,
          parent_task: parent_task
        )

        described_class.call(
          task: subtask,
          attributes: {
            status: "in_progress"
          }
        )

        expect(subtask.reload.status).to eq("in_progress")
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      before do
        project.update!(archived_at: Time.current)
      end

      it "タスクを更新せず、エラーを返す" do
        original_title = task.title

        expect do
          described_class.call(
            task: task,
            attributes: {
              title: "更新後のタスク"
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(task.reload.title).to eq(original_title)
      end
    end
  end
end
