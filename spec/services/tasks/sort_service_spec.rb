# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::SortService do
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team) }

  describe ".call" do
    def create_task_with(attributes)
      create(:task, { project: project }.merge(attributes))
    end

    context "手動順でソートする場合" do
      it "positionの昇順で取得する" do
        third_task = create_task_with(position: 2)
        first_task = create_task_with(position: 0)
        second_task = create_task_with(position: 1)

        result = described_class.call(project: project)

        expect(result).to eq([first_task, second_task, third_task])
      end
    end

    context "期限でソートする場合" do
      it "期限の昇順で取得し、期限なしは最後にする" do
        late_task = create_task_with(
          due_date: Date.new(2026, 12, 20), position: 0
        )
        no_due_date_task = create_task_with(due_date: nil, position: 1)
        early_task = create_task_with(
          due_date: Date.new(2026, 12, 10), position: 2
        )

        result = described_class.call(project: project, sort_by: "due_date")

        expect(result).to eq([early_task, late_task, no_due_date_task])
      end

      it "期限が同じ場合はpositionの昇順で取得する" do
        second_task = create_task_with(
          due_date: Date.new(2026, 12, 10), position: 1
        )
        first_task = create_task_with(
          due_date: Date.new(2026, 12, 10), position: 0
        )

        result = described_class.call(project: project, sort_by: "due_date")

        expect(result).to eq([first_task, second_task])
      end
    end

    context "優先度でソートする場合" do
      it "高・中・低の順で取得する" do
        low_task = create_task_with(priority: "low", position: 0)
        high_task = create_task_with(priority: "high", position: 1)
        medium_task = create_task_with(priority: "medium", position: 2)

        result = described_class.call(project: project, sort_by: "priority")

        expect(result).to eq([high_task, medium_task, low_task])
      end

      it "優先度が同じ場合はpositionの昇順で取得する" do
        second_task = create_task_with(priority: "high", position: 1)
        first_task = create_task_with(priority: "high", position: 0)

        result = described_class.call(project: project, sort_by: "priority")

        expect(result).to eq([first_task, second_task])
      end
    end

    context "ステータスでソートする場合" do
      it "未着手・進行中・完了の順で取得する" do
        completed_task = create_task_with(
          status: "completed", position: 0
        )
        in_progress_task = create_task_with(
          status: "in_progress", position: 1
        )
        not_started_task = create_task_with(
          status: "not_started", position: 2
        )

        result = described_class.call(project: project, sort_by: "status")

        expect(result).to eq([
                               not_started_task,
                               in_progress_task,
                               completed_task
                             ])
      end

      it "ステータスが同じ場合はpositionの昇順で取得する" do
        second_task = create_task_with(status: "not_started", position: 1)
        first_task = create_task_with(status: "not_started", position: 0)

        result = described_class.call(project: project, sort_by: "status")

        expect(result).to eq([first_task, second_task])
      end
    end

    context "作成日でソートする場合" do
      it "新しい順で取得する" do
        old_task = create_task_with(
          created_at: Time.zone.parse("2026-11-01 10:00:00"),
          position: 0
        )
        new_task = create_task_with(
          created_at: Time.zone.parse("2026-11-20 10:00:00"),
          position: 1
        )

        result = described_class.call(project: project, sort_by: "created_at")

        expect(result).to eq([new_task, old_task])
      end

      it "作成日時が同じ場合はpositionの昇順で取得する" do
        created_at = Time.zone.parse("2026-11-20 10:00:00")
        second_task = create_task_with(created_at: created_at, position: 1)
        first_task = create_task_with(created_at: created_at, position: 0)

        result = described_class.call(project: project, sort_by: "created_at")

        expect(result).to eq([first_task, second_task])
      end
    end

    context "サブタスクをソートする場合" do
      let(:parent_task) { create(:task, project: project) }

      it "同じ親タスクに属するサブタスクだけを取得する" do
        another_parent_task = create(:task, project: project)

        first_subtask = create_task_with(
          parent_task: parent_task, position: 0
        )
        second_subtask = create_task_with(
          parent_task: parent_task, position: 1
        )
        another_subtask = create_task_with(
          parent_task: another_parent_task, position: 0
        )

        result = described_class.call(
          project: project,
          parent_task_id: parent_task.id
        )

        expect(result).to eq([first_subtask, second_subtask])
        expect(result).not_to include(another_subtask)
      end

      it "別プロジェクトの親タスクを指定した場合は拒否する" do
        another_project = create(:project, team: team)
        another_parent_task = create(:task, project: another_project)

        expect do
          described_class.call(
            project: project,
            parent_task_id: another_parent_task.id
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "サブタスクを親タスクとして指定した場合は拒否する" do
        subtask = create(:task, project: project, parent_task: parent_task)

        expect do
          described_class.call(
            project: project,
            parent_task_id: subtask.id
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "不正なソート条件を指定した場合" do
      it "手動順にフォールバックする" do
        second_task = create_task_with(position: 1)
        first_task = create_task_with(position: 0)

        result = described_class.call(project: project, sort_by: "invalid")

        expect(result).to eq([first_task, second_task])
      end
    end

    context "ソート結果を取得する場合" do
      it "ActiveRecordのRelationを返す" do
        create(:task, project: project)

        result = described_class.call(project: project)

        expect(result).to be_a(ActiveRecord::Relation)
      end

      it "positionを更新しない" do
        first_task = create_task_with(position: 0)
        second_task = create_task_with(position: 1)

        described_class.call(
          project: project,
          sort_by: "created_at"
        ).to_a

        expect(first_task.reload.position).to eq(0)
        expect(second_task.reload.position).to eq(1)
      end
    end
  end
end
