# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::CreateService do
  let(:team) { create(:team) }
  let(:user) { create(:user) }

  describe ".call" do
    context "Ownerの場合" do
      it "プロジェクトを作成し、作成者を初期担当者に設定する" do
        membership = create(
          :team_membership,
          team: team,
          user: user,
          role: "owner"
        )

        project = described_class.call(
          team: team,
          user: user,
          name: "新規プロジェクト",
          description: "プロジェクトの説明",
          due_date: Date.new(2026, 12, 31)
        )

        expect(project).to be_persisted
        expect(project.team).to eq(team)
        expect(project.created_by).to eq(user)
        expect(project.assignee_membership).to eq(membership)
        expect(project.name).to eq("新規プロジェクト")
        expect(project.description).to eq("プロジェクトの説明")
        expect(project.due_date).to eq(Date.new(2026, 12, 31))
        expect(project.status).to eq("順調")
      end
    end

    context "Memberの場合" do
      it "プロジェクトを作成できる" do
        membership = create(
          :team_membership,
          team: team,
          user: user,
          role: "member"
        )

        project = described_class.call(
          team: team,
          user: user,
          name: "新規プロジェクト"
        )

        expect(project).to be_persisted
        expect(project.assignee_membership).to eq(membership)
        expect(project.status).to eq("順調")
      end
    end

    context "Guestの場合" do
      it "プロジェクトを作成できない" do
        create(
          :team_membership,
          team: team,
          user: user,
          role: "guest"
        )

        expect do
          described_class.call(
            team: team,
            user: user,
            name: "新規プロジェクト"
          )
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "チームを離脱済みの場合" do
      it "プロジェクトを作成できない" do
        create(
          :team_membership,
          team: team,
          user: user,
          role: "member",
          status: "left",
          left_at: Time.current
        )

        expect do
          described_class.call(
            team: team,
            user: user,
            name: "新規プロジェクト"
          )
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "チームに所属していない場合" do
      it "プロジェクトを作成できない" do
        expect do
          described_class.call(
            team: team,
            user: user,
            name: "新規プロジェクト"
          )
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "プロジェクト名が不正な場合" do
      it "プロジェクトを作成せず、エラーを返す" do
        create(
          :team_membership,
          team: team,
          user: user,
          role: "owner"
        )

        expect do
          described_class.call(
            team: team,
            user: user,
            name: ""
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(Project.count).to eq(0)
      end
    end

    context "チームとユーザーの所属関係が異なる場合" do
      it "別チームの所属情報ではプロジェクトを作成できない" do
        another_team = create(:team)

        create(
          :team_membership,
          team: another_team,
          user: user,
          role: "owner"
        )

        expect do
          described_class.call(
            team: team,
            user: user,
            name: "新規プロジェクト"
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(Project.count).to eq(0)
      end
    end
  end
end
