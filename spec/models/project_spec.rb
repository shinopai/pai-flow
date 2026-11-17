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

  describe "validations" do
    it "FactoryBotで有効なProjectを生成できること" do
      project = build(:project)

      expect(project).to be_valid
    end

    it "nameが空の場合は無効であること" do
      project = build(:project, name: nil)

      expect(project).not_to be_valid
      expect(project.errors[:name]).to be_present
    end

    it "nameが100文字を超える場合は無効であること" do
      project = build(:project, name: "あ" * 101)

      expect(project).not_to be_valid
      expect(project.errors[:name]).to be_present
    end

    it "descriptionが500文字を超える場合は無効であること" do
      project = build(:project, description: "あ" * 501)

      expect(project).not_to be_valid
      expect(project.errors[:description]).to be_present
    end

    it "statusが空の場合は無効であること" do
      project = build(:project, status: nil)

      expect(project).not_to be_valid
      expect(project.errors[:status]).to be_present
    end

    it "許可されていないstatusの場合は無効であること" do
      project = build(:project, status: "invalid")

      expect(project).not_to be_valid
      expect(project.errors[:status]).to be_present
    end

    it "due_dateに不正な日付を指定した場合は無効であること" do
      project = build(:project, due_date: "invalid-date")

      expect(project).not_to be_valid
      expect(project.errors[:due_date]).to be_present
    end
  end

  describe "associations" do
    it "Teamに所属すること" do
      team = create(:team)
      project = create(:project, team:)

      expect(project.team).to eq(team)
    end

    it "作成者のUserに所属すること" do
      user = create(:user)
      project = create(:project, created_by: user)

      expect(project.created_by).to eq(user)
    end

    it "Assigneeが未設定でも有効であること" do
      project = build(:project, assignee_membership: nil)

      expect(project).to be_valid
    end
  end
end
