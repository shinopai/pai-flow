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

  describe "validations" do
    it "FactoryBotで有効なTaskを生成できること" do
      task = build(:task)

      expect(task).to be_valid
    end

    it "titleが空の場合は無効であること" do
      task = build(:task, title: nil)

      expect(task).not_to be_valid
      expect(task.errors[:title]).to be_present
    end

    it "titleが100文字を超える場合は無効であること" do
      task = build(:task, title: "あ" * 101)

      expect(task).not_to be_valid
      expect(task.errors[:title]).to be_present
    end

    it "descriptionが500文字を超える場合は無効であること" do
      task = build(:task, description: "あ" * 501)

      expect(task).not_to be_valid
      expect(task.errors[:description]).to be_present
    end

    it "priorityが許可されていない値の場合は無効であること" do
      task = build(:task, priority: "invalid")

      expect(task).not_to be_valid
      expect(task.errors[:priority]).to be_present
    end

    it "statusが許可されていない値の場合は無効であること" do
      task = build(:task, status: "invalid")

      expect(task).not_to be_valid
      expect(task.errors[:status]).to be_present
    end

    it "positionが負数の場合は無効であること" do
      task = build(:task, position: -1)

      expect(task).not_to be_valid
      expect(task.errors[:position]).to be_present
    end

    it "due_dateに不正な日付を指定した場合は無効であること" do
      task = build(:task, due_date: "invalid-date")

      expect(task).not_to be_valid
      expect(task.errors[:due_date]).to be_present
    end

    it "AssigneeとParent Taskが未設定でも有効であること" do
      task = build(:task, assignee_membership: nil, parent_task: nil)

      expect(task).to be_valid
    end
  end

  describe "associations" do
    it "Projectに所属すること" do
      project = create(:project)
      task = create(:task, project:)

      expect(task.project).to eq(project)
    end

    it "作成者のUserに所属すること" do
      user = create(:user)
      task = create(:task, created_by: user)

      expect(task.created_by).to eq(user)
    end

    it "Parent Taskに所属すること" do
      parent_task = create(:task)
      subtask = create(:task, project: parent_task.project, parent_task:)

      expect(subtask.parent_task).to eq(parent_task)
    end

    it "複数のSubtaskを持てること" do
      task = create(:task)
      subtasks = create_list(
        :task,
        2,
        project: task.project,
        parent_task: task
      )

      expect(task.subtasks).to match_array(subtasks)
    end
  end
end
