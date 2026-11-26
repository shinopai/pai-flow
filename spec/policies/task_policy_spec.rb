# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskPolicy do
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team) }
  let(:task) { build(:task, project: project) }
  let(:user) { create(:user) }

  describe "タスク作成権限" do
    context "Ownerの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )
      end

      it "タスク作成を許可する" do
        policy = described_class.new(user, task)

        expect(policy.create?).to be true
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

      it "タスク作成を許可する" do
        policy = described_class.new(user, task)

        expect(policy.create?).to be true
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

      it "タスク作成を拒否する" do
        policy = described_class.new(user, task)

        expect(policy.create?).to be false
      end
    end

    context "所属がない場合" do
      it "タスク作成を拒否する" do
        policy = described_class.new(user, task)

        expect(policy.create?).to be false
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

      it "タスク作成を拒否する" do
        policy = described_class.new(user, task)

        expect(policy.create?).to be false
      end
    end

    context "未ログインの場合" do
      it "タスク作成を拒否する" do
        policy = described_class.new(nil, task)

        expect(policy.create?).to be false
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )

        project.update!(archived_at: Time.current)
      end

      it "タスク作成を拒否する" do
        policy = described_class.new(user, task)

        expect(policy.create?).to be false
      end
    end
  end

  describe "タスク編集権限" do
    context "Ownerの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )
      end

      it "タスク編集を許可する" do
        policy = described_class.new(user, task)

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

      it "タスク編集を許可する" do
        policy = described_class.new(user, task)

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

      it "タスク編集を拒否する" do
        policy = described_class.new(user, task)

        expect(policy.update?).to be false
      end
    end

    context "所属がない場合" do
      it "タスク編集を拒否する" do
        policy = described_class.new(user, task)

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

      it "タスク編集を拒否する" do
        policy = described_class.new(user, task)

        expect(policy.update?).to be false
      end
    end

    context "未ログインの場合" do
      it "タスク編集を拒否する" do
        policy = described_class.new(nil, task)

        expect(policy.update?).to be false
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )

        project.update!(archived_at: Time.current)
      end

      it "タスク編集を拒否する" do
        policy = described_class.new(user, task)

        expect(policy.update?).to be false
      end
    end
  end

  describe "タスク削除権限" do
    context "Ownerの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )
      end

      it "タスク削除を許可する" do
        policy = described_class.new(user, task)

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

      it "タスク削除を許可する" do
        policy = described_class.new(user, task)

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

      it "タスク削除を拒否する" do
        policy = described_class.new(user, task)

        expect(policy.destroy?).to be false
      end
    end

    context "所属がない場合" do
      it "タスク削除を拒否する" do
        policy = described_class.new(user, task)

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

      it "タスク削除を拒否する" do
        policy = described_class.new(user, task)

        expect(policy.destroy?).to be false
      end
    end

    context "未ログインの場合" do
      it "タスク削除を拒否する" do
        policy = described_class.new(nil, task)

        expect(policy.destroy?).to be false
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      before do
        create(
          :team_membership,
          user: user,
          team: team,
          role: "owner"
        )

        project.update!(archived_at: Time.current)
      end

      it "タスク削除を拒否する" do
        policy = described_class.new(user, task)

        expect(policy.destroy?).to be false
      end
    end
  end
end
