# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamPolicy do
  describe "一覧表示権限" do
    context "ログイン済みの場合" do
      let(:user) { create(:user) }
      let(:policy) { described_class.new(user, Team) }

      it "チーム一覧へのアクセスを許可する" do
        expect(policy.index?).to be true
      end
    end

    context "未ログインの場合" do
      let(:policy) { described_class.new(nil, Team) }

      it "チーム一覧へのアクセスを拒否する" do
        expect(policy.index?).to be false
      end
    end
  end

  describe "チーム表示・選択権限" do
    let(:user) { create(:user) }
    let(:team) { create(:team) }
    let(:policy) { described_class.new(user, team) }

    context "有効な所属がある場合" do
      before do
        create(:team_membership, user: user, team: team)
      end

      it "チーム表示と選択を許可する" do
        expect(policy.show?).to be true
        expect(policy.select?).to be true
      end
    end

    context "所属がない場合" do
      it "チーム表示と選択を拒否する" do
        expect(policy.show?).to be false
        expect(policy.select?).to be false
      end
    end

    context "所属がleftの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          status: "left",
          left_at: Time.current
        )
      end

      it "チーム表示と選択を拒否する" do
        expect(policy.show?).to be false
        expect(policy.select?).to be false
      end
    end

    context "未ログインの場合" do
      let(:policy) { described_class.new(nil, team) }

      it "チーム表示と選択を拒否する" do
        expect(policy.show?).to be false
        expect(policy.select?).to be false
      end
    end
  end

  describe "チーム名変更権限" do
    let(:user) { create(:user) }
    let(:team) { create(:team) }
    let(:policy) { described_class.new(user, team) }

    context "Ownerの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )
      end

      it "チーム設定画面へのアクセスとチーム名変更を許可する" do
        expect(policy.edit?).to be true
        expect(policy.update?).to be true
      end
    end

    context "Memberの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "member"
        )
      end

      it "チーム設定画面へのアクセスとチーム名変更を拒否する" do
        expect(policy.edit?).to be false
        expect(policy.update?).to be false
      end
    end

    context "Guestの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "guest"
        )
      end

      it "チーム設定画面へのアクセスとチーム名変更を拒否する" do
        expect(policy.edit?).to be false
        expect(policy.update?).to be false
      end
    end

    context "所属がない場合" do
      it "チーム設定画面へのアクセスとチーム名変更を拒否する" do
        expect(policy.edit?).to be false
        expect(policy.update?).to be false
      end
    end
  end

  describe "Scope" do
    describe "#resolve" do
      it "ユーザーの有効な所属チームだけを返す" do
        user = create(:user)
        active_team = create(:team)
        left_team = create(:team)
        create(:team)

        create(:team_membership, user: user, team: active_team)
        create(
          :team_membership,
          user: user,
          team: left_team,
          status: "left",
          left_at: Time.current
        )

        scope = described_class::Scope.new(user, Team.all)

        expect(scope.resolve).to contain_exactly(active_team)
      end

      it "未ログインの場合は空のRelationを返す" do
        scope = described_class::Scope.new(nil, Team.all)

        expect(scope.resolve).to be_empty
      end
    end
  end
end
