# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::ListService do
  let(:team) { create(:team) }

  describe ".call" do
    it "指定チームのプロジェクトを取得する" do
      project = create(:project, team: team)

      result = described_class.call(team: team)

      expect(result).to contain_exactly(project)
    end

    it "完了したプロジェクトも取得する" do
      project = create(
        :project,
        team: team,
        status: "完了"
      )

      result = described_class.call(team: team)

      expect(result).to contain_exactly(project)
    end

    it "アーカイブ済みプロジェクトを除外する" do
      create(
        :project,
        team: team,
        archived_at: Time.current
      )

      result = described_class.call(team: team)

      expect(result).to be_empty
    end

    it "別チームのプロジェクトを取得しない" do
      another_team_project = create(:project)

      result = described_class.call(team: team)

      expect(result).not_to include(another_team_project)
    end

    it "担当者の所属情報とユーザー情報を取得できる" do
      user = create(:user)
      membership = create(
        :team_membership,
        team: team,
        user: user,
        role: "owner"
      )
      project = create(
        :project,
        team: team,
        assignee_membership: membership
      )

      result = described_class.call(team: team)

      expect(result.first.assignee_membership.user).to eq(user)
      expect(result.first).to eq(project)
    end
  end
end
