# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationPolicy do
  describe "基本権限" do
    let(:user) { create(:user) }
    let(:team) { create(:team) }
    let(:policy) { described_class.new(user, team) }

    it "各権限をデフォルトで拒否する" do
      expect(policy.index?).to be false
      expect(policy.show?).to be false
      expect(policy.create?).to be false
      expect(policy.new?).to be false
      expect(policy.update?).to be false
      expect(policy.edit?).to be false
      expect(policy.destroy?).to be false
    end
  end

  describe "#team" do
    let(:team) { create(:team) }

    it "Teamから所属チームを取得できる" do
      policy = described_class.new(nil, team)

      expect(policy.send(:team)).to eq(team)
    end

    it "TeamMembershipから所属チームを取得できる" do
      membership = create(:team_membership, team: team)
      policy = described_class.new(nil, membership)

      expect(policy.send(:team)).to eq(team)
    end

    it "Invitationから所属チームを取得できる" do
      invitation = Invitation.new(team: team)
      policy = described_class.new(nil, invitation)

      expect(policy.send(:team)).to eq(team)
    end

    it "Projectから所属チームを取得できる" do
      project = create(:project, team: team)
      policy = described_class.new(nil, project)

      expect(policy.send(:team)).to eq(team)
    end

    it "Taskから所属チームを取得できる" do
      task = create(:task, project: create(:project, team: team))
      policy = described_class.new(nil, task)

      expect(policy.send(:team)).to eq(team)
    end

    it "Commentから所属チームを取得できる" do
      comment = create(:comment)
      policy = described_class.new(nil, comment)

      expect(policy.send(:team)).to eq(comment.task.project.team)
    end

    it "対象が未対応のレコードならnilを返す" do
      policy = described_class.new(nil, User.new)

      expect(policy.send(:team)).to be_nil
    end
  end

  describe "所属・ロール判定" do
    let(:user) { create(:user) }
    let(:team) { create(:team) }
    let(:policy) { described_class.new(user, team) }

    context "Ownerの場合" do
      before do
        create(:team_membership, :owner, user: user, team: team)
      end

      it "有効な所属とOwner権限を判定できる" do
        expect(policy.send(:active_member?)).to be true
        expect(policy.send(:owner?)).to be true
        expect(policy.send(:owner_or_member?)).to be true
        expect(policy.send(:guest?)).to be false
      end
    end

    context "Memberの場合" do
      before do
        create(:team_membership, user: user, team: team, role: "member")
      end

      it "Member権限を判定できる" do
        expect(policy.send(:owner?)).to be false
        expect(policy.send(:owner_or_member?)).to be true
        expect(policy.send(:guest?)).to be false
      end
    end

    context "Guestの場合" do
      before do
        create(:team_membership, :guest, user: user, team: team)
      end

      it "Guest権限を判定できる" do
        expect(policy.send(:owner?)).to be false
        expect(policy.send(:owner_or_member?)).to be false
        expect(policy.send(:guest?)).to be true
      end
    end

    context "所属がない場合" do
      it "権限をすべて拒否する" do
        expect(policy.send(:active_member?)).to be false
        expect(policy.send(:owner?)).to be false
        expect(policy.send(:owner_or_member?)).to be false
        expect(policy.send(:guest?)).to be false
      end
    end

    context "所属がleftの場合" do
      before do
        create(:team_membership, user: user, team: team, status: "left", left_at: Time.current)
      end

      it "有効な所属として扱わない" do
        expect(policy.send(:active_member?)).to be false
      end
    end

    context "未ログインの場合" do
      let(:policy) { described_class.new(nil, team) }

      it "所属・権限を取得できない" do
        expect(policy.send(:active_membership)).to be_nil
        expect(policy.send(:active_member?)).to be false
        expect(policy.send(:owner?)).to be false
        expect(policy.send(:owner_or_member?)).to be false
        expect(policy.send(:guest?)).to be false
      end
    end
  end

  describe "Scope" do
    describe "#active_team_ids" do
      it "ユーザーの有効な所属チームだけを取得する" do
        user = create(:user)
        active_team = create(:team)
        left_team = create(:team)

        create(:team_membership, user: user, team: active_team, status: "active")
        create(:team_membership, user: user, team: left_team, status: "left", left_at: Time.current)

        scope = described_class::Scope.new(user, Team.all)

        expect(scope.send(:active_team_ids).pluck(:team_id)).to contain_exactly(active_team.id)
      end

      it "未ログインの場合は空のRelationを返す" do
        scope = described_class::Scope.new(nil, Team.all)

        expect(scope.send(:active_team_ids)).to be_empty
      end
    end

    describe "#resolve" do
      it "サブクラスで実装されていない場合は例外を発生させる" do
        scope = described_class::Scope.new(nil, Team.all)

        expect { scope.resolve }.to raise_error(NoMethodError)
      end
    end
  end
end
