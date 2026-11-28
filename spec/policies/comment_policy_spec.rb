# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommentPolicy do
  let(:team) { create(:team) }
  let(:user) { create(:user) }
  let(:membership) do
    create(:team_membership, team: team, user: user, role: "owner")
  end
  let(:project) { create(:project, team: team) }
  let(:task) { create(:task, project: project) }
  let(:comment) do
    create(:comment, task: task, team_membership: membership)
  end

  describe "コメント編集権限" do
    it "投稿者本人でOwnerの場合は許可する" do
      expect(described_class.new(user, comment).update?).to be true
    end

    it "投稿者本人でMemberの場合は許可する" do
      membership.update!(role: "member")

      expect(described_class.new(user, comment).update?).to be true
    end

    it "投稿者本人でもGuestの場合は拒否する" do
      membership.update!(role: "guest")

      expect(described_class.new(user, comment).update?).to be false
    end

    it "他のユーザーの場合は拒否する" do
      other_user = create(:user)

      expect(described_class.new(other_user, comment).update?).to be false
    end

    it "投稿時の所属がleftの場合は拒否する" do
      membership.update!(status: "left", left_at: Time.current)

      expect(described_class.new(user, comment).update?).to be false
    end

    it "再加入後も以前の所属で投稿したコメントは編集できない" do
      membership.update!(status: "left", left_at: Time.current)

      create(
        :team_membership,
        team: team,
        user: user,
        role: "owner"
      )

      expect(described_class.new(user, comment).update?).to be false
    end

    it "アーカイブ済みプロジェクトでは拒否する" do
      project.update!(archived_at: Time.current)

      expect(described_class.new(user, comment).update?).to be false
    end

    it "未ログインの場合は拒否する" do
      expect(described_class.new(nil, comment).update?).to be false
    end
  end

  describe "コメント削除権限" do
    it "編集権限がある投稿者本人には許可する" do
      expect(described_class.new(user, comment).destroy?).to be true
    end

    it "編集権限がない場合は拒否する" do
      membership.update!(role: "guest")

      expect(described_class.new(user, comment).destroy?).to be false
    end
  end
end
