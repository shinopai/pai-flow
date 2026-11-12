require "rails_helper"

RSpec.describe Project, type: :model do
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
        title: "テストタスク",
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
        title: "テストサブタスク",
        priority: "medium",
        status: "not_started",
        position: 0
      )
    end

    let!(:comment) do
      create(:comment, task:, team_membership: membership, body: "テストコメント")
    end

    let!(:subtask_comment) do
      create(
        :comment,
        task: subtask,
        team_membership: membership,
        body: "サブタスクのコメント"
      )
    end

    it "Projectを削除するとTask・Subtask・Commentも削除される" do
      expect { project.destroy }
        .to change(Project, :count).by(-1)
        .and change(Task, :count).by(-2)
        .and change(Comment, :count).by(-2)

      expect(Project.exists?(project.id)).to be false
      expect(Task.exists?(task.id)).to be false
      expect(Task.exists?(subtask.id)).to be false
      expect(Comment.exists?(comment.id)).to be false
      expect(Comment.exists?(subtask_comment.id)).to be false
    end
  end
end
