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
end
