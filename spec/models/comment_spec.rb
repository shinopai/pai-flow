require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "validations" do
    it "FactoryBotで有効なCommentを生成できること" do
      comment = build(:comment)

      expect(comment).to be_valid
    end

    it "bodyが空の場合は無効であること" do
      comment = build(:comment, body: nil)

      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to be_present
    end

    it "bodyが1000文字を超える場合は無効であること" do
      comment = build(:comment, body: "あ" * 1001)

      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to be_present
    end
  end

  describe "associations" do
    it "Taskに所属すること" do
      task = create(:task)
      comment = create(:comment, task:)

      expect(comment.task).to eq(task)
    end

    it "TeamMembershipに所属すること" do
      team_membership = create(:team_membership)
      comment = create(:comment, team_membership:)

      expect(comment.team_membership).to eq(team_membership)
    end
  end
end
