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

    context "プロジェクト名検索" do
      it "プロジェクト名の部分一致で検索する" do
        matched = create(
          :project,
          team: team,
          name: "PaiFlow開発"
        )
        create(
          :project,
          team: team,
          name: "別プロジェクト"
        )

        result = described_class.call(
          team: team,
          filters: { keyword: "Flow" }
        )

        expect(result).to contain_exactly(matched)
      end

      it "英字の大文字小文字を区別しない" do
        matched = create(
          :project,
          team: team,
          name: "PaiFlow開発"
        )

        result = described_class.call(
          team: team,
          filters: { keyword: "paiflow" }
        )

        expect(result).to contain_exactly(matched)
      end

      it "検索キーワードの前後の空白を除去する" do
        matched = create(
          :project,
          team: team,
          name: "PaiFlow開発"
        )

        result = described_class.call(
          team: team,
          filters: { keyword: "  PaiFlow  " }
        )

        expect(result).to contain_exactly(matched)
      end

      it "空白のみのキーワードでは絞り込まない" do
        first = create(:project, team: team)
        second = create(:project, team: team)

        result = described_class.call(
          team: team,
          filters: { keyword: "   " }
        )

        expect(result).to contain_exactly(first, second)
      end
    end

    context "ステータス絞り込み" do
      it "指定したステータスのプロジェクトを取得する" do
        matched = create(
          :project,
          team: team,
          status: "順調"
        )
        create(
          :project,
          team: team,
          status: "完了"
        )

        result = described_class.call(
          team: team,
          filters: { status: "順調" }
        )

        expect(result).to contain_exactly(matched)
      end

      it "不正なステータスでは検索結果が空になる" do
        create(:project, team: team)

        result = described_class.call(
          team: team,
          filters: { status: "不正なステータス" }
        )

        expect(result).to be_empty
      end
    end

    context "担当者絞り込み" do
      let(:membership) do
        create(
          :team_membership,
          team: team,
          role: "owner"
        )
      end

      it "指定した担当者のプロジェクトを取得する" do
        matched = create(
          :project,
          team: team,
          assignee_membership: membership
        )
        create(:project, team: team)

        result = described_class.call(
          team: team,
          filters: { assignee_id: membership.id }
        )

        expect(result).to contain_exactly(matched)
      end

      it "担当者未設定のプロジェクトを取得する" do
        matched = create(
          :project,
          team: team,
          assignee_membership: nil
        )
        create(
          :project,
          team: team,
          assignee_membership: membership
        )

        result = described_class.call(
          team: team,
          filters: { assignee_id: "unassigned" }
        )

        expect(result).to contain_exactly(matched)
      end

      it "不正な担当者IDでは検索結果が空になる" do
        create(:project, team: team)

        result = described_class.call(
          team: team,
          filters: { assignee_id: "invalid" }
        )

        expect(result).to be_empty
      end
    end

    context "期限絞り込み" do
      let!(:first_due_project) do
        create(
          :project,
          team: team,
          due_date: Date.new(2026, 12, 10)
        )
      end
      let!(:second_due_project) do
        create(
          :project,
          team: team,
          due_date: Date.new(2026, 12, 20)
        )
      end
      let!(:before_range_project) do
        create(
          :project,
          team: team,
          due_date: Date.new(2026, 12, 9)
        )
      end
      let!(:after_range_project) do
        create(
          :project,
          team: team,
          due_date: Date.new(2026, 12, 21)
        )
      end

      it "開始日以降のプロジェクトを取得する" do
        result = described_class.call(
          team: team,
          filters: { due_date_from: "2026-12-10" }
        )

        expect(result).to contain_exactly(
          first_due_project,
          second_due_project,
          after_range_project
        )
      end

      it "終了日以前のプロジェクトを取得する" do
        result = described_class.call(
          team: team,
          filters: { due_date_to: "2026-12-10" }
        )

        expect(result).to contain_exactly(
          first_due_project,
          before_range_project
        )
      end

      it "開始日と終了日の両方を含む期間で検索する" do
        result = described_class.call(
          team: team,
          filters: {
            due_date_from: "2026-12-10",
            due_date_to: "2026-12-20"
          }
        )

        expect(result).to contain_exactly(
          first_due_project,
          second_due_project
        )
      end

      it "開始日が終了日より後の場合はエラーになる" do
        expect do
          described_class.call(
            team: team,
            filters: {
              due_date_from: "2026-12-20",
              due_date_to: "2026-12-10"
            }
          )
        end.to raise_error(
          Projects::ListService::InvalidDateRange
        )
      end

      it "不正な日付の場合はエラーになる" do
        expect do
          described_class.call(
            team: team,
            filters: { due_date_from: "invalid" }
          )
        end.to raise_error(
          Projects::ListService::InvalidDateRange
        )
      end
    end

    context "検索条件の組み合わせ" do
      let!(:matched_project) do
        create(
          :project,
          team: team,
          name: "PaiFlow開発",
          status: "順調",
          due_date: Date.new(2026, 12, 10)
        )
      end
      let!(:other_status_project) do
        create(
          :project,
          team: team,
          name: "PaiFlow別案件",
          status: "完了",
          due_date: Date.new(2026, 12, 10)
        )
      end
      let!(:other_keyword_project) do
        create(
          :project,
          team: team,
          name: "別プロジェクト",
          status: "順調",
          due_date: Date.new(2026, 12, 10)
        )
      end

      it "複数の検索条件をAND条件で適用する" do
        result = described_class.call(
          team: team,
          filters: {
            keyword: "PaiFlow",
            status: "順調",
            due_date_from: "2026-12-01",
            due_date_to: "2026-12-31"
          }
        )

        expect(result).to contain_exactly(matched_project)
      end
    end

    context "並び替え" do
      it "更新日時の降順で取得する" do
        older = create(
          :project,
          team: team,
          created_at: 2.days.ago,
          updated_at: 2.days.ago
        )
        newer = create(
          :project,
          team: team,
          created_at: 1.day.ago,
          updated_at: 1.day.ago
        )

        result = described_class.call(team: team)

        expect(result.to_a).to eq([newer, older])
      end

      it "期限の昇順で取得し、期限なしを最後にする" do
        later = create(
          :project,
          team: team,
          due_date: Date.new(2026, 12, 20)
        )
        earlier = create(
          :project,
          team: team,
          due_date: Date.new(2026, 12, 10)
        )
        no_due_date = create(
          :project,
          team: team,
          due_date: nil
        )

        result = described_class.call(
          team: team,
          filters: { sort: "due_date" }
        )

        expect(result.to_a).to eq([earlier, later, no_due_date])
      end

      it "プロジェクト名の昇順で取得する" do
        second = create(
          :project,
          team: team,
          name: "Bプロジェクト"
        )
        first = create(
          :project,
          team: team,
          name: "Aプロジェクト"
        )

        result = described_class.call(
          team: team,
          filters: { sort: "name" }
        )

        expect(result.to_a).to eq([first, second])
      end

      it "不正な並び替え指定では更新日時の降順にする" do
        older = create(
          :project,
          team: team,
          created_at: 2.days.ago,
          updated_at: 2.days.ago
        )
        newer = create(
          :project,
          team: team,
          created_at: 1.day.ago,
          updated_at: 1.day.ago
        )

        result = described_class.call(
          team: team,
          filters: { sort: "invalid" }
        )

        expect(result.to_a).to eq([newer, older])
      end
    end
  end
end
