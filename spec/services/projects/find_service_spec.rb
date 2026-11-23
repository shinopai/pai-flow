# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::FindService do
  let(:team) { create(:team) }

  describe ".call" do
    it "指定チームのプロジェクトを取得する" do
      project = create(:project, team: team)

      result = described_class.call(
        team: team,
        id: project.id
      )

      expect(result).to eq(project)
    end

    it "アーカイブ済みプロジェクトも取得する" do
      project = create(
        :project,
        team: team,
        archived_at: Time.current
      )

      result = described_class.call(
        team: team,
        id: project.id
      )

      expect(result).to eq(project)
    end

    it "別チームのプロジェクトは取得できない" do
      another_team_project = create(:project)

      expect do
        described_class.call(
          team: team,
          id: another_team_project.id
        )
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "存在しないIDでは取得できない" do
      expect do
        described_class.call(
          team: team,
          id: -1
        )
      end.to raise_error(ActiveRecord::RecordNotFound)
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

      result = described_class.call(
        team: team,
        id: project.id
      )

      expect(result.assignee_membership.user).to eq(user)
    end
  end
end
