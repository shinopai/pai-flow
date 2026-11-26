# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::DestroyService do
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team) }
  let(:task) { create(:task, project: project) }

  describe ".call" do
    context "通常タスクの場合" do
      it "タスク・サブタスク・関連コメントをすべて削除する" do
        subtask = create(
          :task,
          project: project,
          parent_task: task
        )
        task_comment = create(:comment, task: task)
        subtask_comment = create(:comment, task: subtask)

        expect do
          described_class.call(task: task)
        end.to change(Task, :count).by(-2)
                                   .and change(Comment, :count).by(-2)

        expect(Task.exists?(task.id)).to be(false)
        expect(Task.exists?(subtask.id)).to be(false)
        expect(Comment.exists?(task_comment.id)).to be(false)
        expect(Comment.exists?(subtask_comment.id)).to be(false)
      end
    end

    context "サブタスクの場合" do
      it "サブタスクと関連コメントだけを削除する" do
        parent_task = create(:task, project: project)
        subtask = create(
          :task,
          project: project,
          parent_task: parent_task
        )
        sibling_subtask = create(
          :task,
          project: project,
          parent_task: parent_task
        )

        parent_comment = create(:comment, task: parent_task)
        subtask_comment = create(:comment, task: subtask)
        sibling_comment = create(:comment, task: sibling_subtask)

        expect do
          described_class.call(task: subtask)
        end.to change(Task, :count).by(-1)
                                   .and change(Comment, :count).by(-1)

        expect(Task.exists?(parent_task.id)).to be(true)
        expect(Task.exists?(subtask.id)).to be(false)
        expect(Task.exists?(sibling_subtask.id)).to be(true)

        expect(Comment.exists?(parent_comment.id)).to be(true)
        expect(Comment.exists?(subtask_comment.id)).to be(false)
        expect(Comment.exists?(sibling_comment.id)).to be(true)
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      before do
        project.update!(archived_at: Time.current)
      end

      it "タスクを削除せず、エラーを返す" do
        original_task_id = task.id

        expect do
          described_class.call(task: task)
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(Task.exists?(original_task_id)).to be(true)
      end
    end
  end
end
