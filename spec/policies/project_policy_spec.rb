# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectPolicy do
  describe "プロジェクト作成権限" do
    let(:team) { create(:team) }
    let(:project) { build(:project, team: team) }

    context "Ownerの場合" do
      let(:user) { create(:user) }

      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )
      end

      it "プロジェクト作成を許可する" do
        policy = described_class.new(user, project)

        expect(policy.create?).to be true
      end
    end

    context "Memberの場合" do
      let(:user) { create(:user) }

      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "member"
        )
      end

      it "プロジェクト作成を許可する" do
        policy = described_class.new(user, project)

        expect(policy.create?).to be true
      end
    end

    context "Guestの場合" do
      let(:user) { create(:user) }

      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "guest"
        )
      end

      it "プロジェクト作成を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.create?).to be false
      end
    end

    context "所属がない場合" do
      let(:user) { create(:user) }

      it "プロジェクト作成を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.create?).to be false
      end
    end

    context "所属がleftの場合" do
      let(:user) { create(:user) }

      before do
        create(
          :team_membership,
          user: user,
          team: team,
          status: "left",
          left_at: Time.current
        )
      end

      it "プロジェクト作成を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.create?).to be false
      end
    end

    context "未ログインの場合" do
      it "プロジェクト作成を拒否する" do
        policy = described_class.new(nil, project)

        expect(policy.create?).to be false
      end
    end
  end

  describe "プロジェクト更新権限" do
    let(:team) { create(:team) }
    let(:project) { create(:project, team: team) }
    let(:user) { create(:user) }

    context "Ownerの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )
      end

      it "プロジェクト更新を許可する" do
        policy = described_class.new(user, project)

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

      it "プロジェクト更新を許可する" do
        policy = described_class.new(user, project)

        expect(policy.update?).to be true
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

      it "プロジェクト更新を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.update?).to be false
      end
    end

    context "所属がない場合" do
      it "プロジェクト更新を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.update?).to be false
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

      it "プロジェクト更新を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.update?).to be false
      end
    end

    context "未ログインの場合" do
      it "プロジェクト更新を拒否する" do
        policy = described_class.new(nil, project)

        expect(policy.update?).to be false
      end
    end

    context "アーカイブ済みの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )

        project.update!(archived_at: Time.current)
      end

      it "プロジェクト更新を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.update?).to be false
      end
    end
  end

  describe "プロジェクトアーカイブ権限" do
    let(:team) { create(:team) }
    let(:project) { create(:project, team: team) }
    let(:user) { create(:user) }

    context "Ownerの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )
      end

      it "プロジェクトアーカイブを許可する" do
        policy = described_class.new(user, project)

        expect(policy.archive?).to be true
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

      it "プロジェクトアーカイブを許可する" do
        policy = described_class.new(user, project)

        expect(policy.archive?).to be true
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

      it "プロジェクトアーカイブを拒否する" do
        policy = described_class.new(user, project)

        expect(policy.archive?).to be false
      end
    end

    context "所属がない場合" do
      it "プロジェクトアーカイブを拒否する" do
        policy = described_class.new(user, project)

        expect(policy.archive?).to be false
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

      it "プロジェクトアーカイブを拒否する" do
        policy = described_class.new(user, project)

        expect(policy.archive?).to be false
      end
    end

    context "未ログインの場合" do
      it "プロジェクトアーカイブを拒否する" do
        policy = described_class.new(nil, project)

        expect(policy.archive?).to be false
      end
    end
  end

  describe "プロジェクト復元権限" do
    let(:team) { create(:team) }
    let(:project) { create(:project, team: team, archived_at: Time.current) }
    let(:user) { create(:user) }

    context "Ownerの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )
      end

      it "プロジェクト復元を許可する" do
        policy = described_class.new(user, project)

        expect(policy.restore?).to be true
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

      it "プロジェクト復元を許可する" do
        policy = described_class.new(user, project)

        expect(policy.restore?).to be true
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

      it "プロジェクト復元を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.restore?).to be false
      end
    end

    context "所属がない場合" do
      it "プロジェクト復元を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.restore?).to be false
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

      it "プロジェクト復元を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.restore?).to be false
      end
    end

    context "未ログインの場合" do
      it "プロジェクト復元を拒否する" do
        policy = described_class.new(nil, project)

        expect(policy.restore?).to be false
      end
    end
  end

  describe "プロジェクト削除権限" do
    let(:team) { create(:team) }
    let(:project) { create(:project, team: team) }
    let(:user) { create(:user) }

    context "Ownerの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )
      end

      it "プロジェクト削除を許可する" do
        policy = described_class.new(user, project)

        expect(policy.destroy?).to be true
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

      it "プロジェクト削除を許可する" do
        policy = described_class.new(user, project)

        expect(policy.destroy?).to be true
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

      it "プロジェクト削除を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.destroy?).to be false
      end
    end

    context "所属がない場合" do
      it "プロジェクト削除を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.destroy?).to be false
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

      it "プロジェクト削除を拒否する" do
        policy = described_class.new(user, project)

        expect(policy.destroy?).to be false
      end
    end

    context "未ログインの場合" do
      it "プロジェクト削除を拒否する" do
        policy = described_class.new(nil, project)

        expect(policy.destroy?).to be false
      end
    end

    context "アーカイブ済みの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )

        project.update!(archived_at: Time.current)
      end

      it "プロジェクト削除を許可する" do
        policy = described_class.new(user, project)

        expect(policy.destroy?).to be true
      end
    end
  end

  describe "タスク並び替え権限" do
    let(:team) { create(:team) }
    let(:project) { create(:project, team: team) }
    let(:user) { create(:user) }

    context "Ownerの場合" do
      before do
        create(:team_membership, user: user, team: team, role: "owner")
      end

      it "タスク並び替えを許可する" do
        policy = described_class.new(user, project)

        expect(policy.reorder?).to be true
      end
    end

    context "Memberの場合" do
      before do
        create(:team_membership, user: user, team: team, role: "member")
      end

      it "タスク並び替えを許可する" do
        policy = described_class.new(user, project)

        expect(policy.reorder?).to be true
      end
    end

    context "Guestの場合" do
      before do
        create(:team_membership, user: user, team: team, role: "guest")
      end

      it "タスク並び替えを拒否する" do
        policy = described_class.new(user, project)

        expect(policy.reorder?).to be false
      end
    end

    context "所属がない場合" do
      it "タスク並び替えを拒否する" do
        policy = described_class.new(user, project)

        expect(policy.reorder?).to be false
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

      it "タスク並び替えを拒否する" do
        policy = described_class.new(user, project)

        expect(policy.reorder?).to be false
      end
    end

    context "未ログインの場合" do
      it "タスク並び替えを拒否する" do
        policy = described_class.new(nil, project)

        expect(policy.reorder?).to be false
      end
    end

    context "アーカイブ済みの場合" do
      before do
        create(:team_membership, user: user, team: team, role: "owner")
        project.update!(archived_at: Time.current)
      end

      it "タスク並び替えを拒否する" do
        policy = described_class.new(user, project)

        expect(policy.reorder?).to be false
      end
    end
  end
end
