require "rails_helper"

RSpec.describe Task, type: :model do
  describe "関連データの削除" do
    let!(:user) { create(:user) }
    let!(:team) { create(:team) }
    let!(:membership) { create(:team_membership, team:, user:) }

    let!(:project) do
      create(
        :project,
        team:,
        created_by: user,
        name: "テストプロジェクト",
        status: "順調"
      )
    end

    let!(:task) do
      create(
        :task,
        project:,
        created_by: user,
        title: "削除対象タスク",
        priority: "high",
        status: "not_started",
        position: 0
      )
    end

    let!(:subtask) do
      create(
        :task,
        project:,
        parent_task: task,
        created_by: user,
        title: "削除対象サブタスク",
        priority: "medium",
        status: "not_started",
        position: 0
      )
    end

    let!(:other_task) do
      create(
        :task,
        project:,
        created_by: user,
        title: "別のタスク",
        priority: "low",
        status: "not_started",
        position: 1
      )
    end

    let!(:comment) do
      create(:comment, task:, team_membership: membership, body: "タスクのコメント")
    end

    let!(:subtask_comment) do
      create(
        :comment,
        task: subtask,
        team_membership: membership,
        body: "サブタスクのコメント"
      )
    end

    it "Taskを削除するとSubtask・関連Commentが削除される" do
      expect { task.destroy }
        .to change(Task, :count).by(-2)
        .and change(Comment, :count).by(-2)

      expect(Task.exists?(task.id)).to be false
      expect(Task.exists?(subtask.id)).to be false
      expect(Task.exists?(other_task.id)).to be true
      expect(Comment.exists?(comment.id)).to be false
      expect(Comment.exists?(subtask_comment.id)).to be false
      expect(Project.exists?(project.id)).to be true
    end
  end
end
