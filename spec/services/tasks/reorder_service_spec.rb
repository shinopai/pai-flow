# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::ReorderService do
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team) }

  describe ".call" do
    context "通常タスクを並び替える場合" do
      it "指定された順序でpositionを更新する" do
        first_task = create(:task, project: project, position: 0)
        second_task = create(:task, project: project, position: 1)
        third_task = create(:task, project: project, position: 2)

        described_class.call(
          project: project,
          task_ids: [third_task.id, first_task.id, second_task.id]
        )

        expect(third_task.reload.position).to eq(0)
        expect(first_task.reload.position).to eq(1)
        expect(second_task.reload.position).to eq(2)
      end

      it "サブタスクを通常タスクの並び替え対象に含めない" do
        first_task = create(:task, project: project, position: 0)
        second_task = create(:task, project: project, position: 1)
        subtask = create(
          :task,
          project: project,
          parent_task: first_task,
          position: 0
        )

        described_class.call(
          project: project,
          task_ids: [second_task.id, first_task.id]
        )

        expect(second_task.reload.position).to eq(0)
        expect(first_task.reload.position).to eq(1)
        expect(subtask.reload.position).to eq(0)
      end
    end

    context "サブタスクを並び替える場合" do
      let(:parent_task) { create(:task, project: project) }

      let!(:subtasks) do
        Array.new(3) do |index|
          create(
            :task,
            project: project,
            parent_task: parent_task,
            position: index
          )
        end
      end

      it "同じ親タスクに属するサブタスクのpositionを更新する" do
        ordered_subtasks = [subtasks[2], subtasks[0], subtasks[1]]

        described_class.call(
          project: project,
          parent_task_id: parent_task.id,
          task_ids: ordered_subtasks.map(&:id)
        )

        expect(
          ordered_subtasks.map { |task| task.reload.position }
        ).to eq([0, 1, 2])
      end

      it "別の親タスクに属するサブタスクのpositionを変更しない" do
        another_parent_task = create(:task, project: project)
        another_subtask = create(
          :task,
          project: project,
          parent_task: another_parent_task,
          position: 5
        )

        described_class.call(
          project: project,
          parent_task_id: parent_task.id,
          task_ids: [subtasks.first.id, subtasks.second.id, subtasks.third.id]
        )

        expect(another_subtask.reload.position).to eq(5)
      end
    end

    context "対象タスクが存在しない場合" do
      it "空配列を受け付ける" do
        expect do
          described_class.call(
            project: project,
            task_ids: []
          )
        end.not_to raise_error
      end
    end

    context "指定されたタスクIDが不正な場合" do
      let!(:first_task) do
        create(:task, project: project, position: 0)
      end
      let!(:second_task) do
        create(:task, project: project, position: 1)
      end

      it "重複したIDを拒否する" do
        expect do
          described_class.call(
            project: project,
            task_ids: [first_task.id, first_task.id]
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(first_task.reload.position).to eq(0)
        expect(second_task.reload.position).to eq(1)
      end

      it "対象外のタスクIDを拒否する" do
        another_project = create(:project, team: team)
        another_task = create(:task, project: another_project)

        expect do
          described_class.call(
            project: project,
            task_ids: [first_task.id, another_task.id]
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(first_task.reload.position).to eq(0)
        expect(second_task.reload.position).to eq(1)
      end

      it "一部のタスクIDだけを指定した場合は拒否する" do
        expect do
          described_class.call(
            project: project,
            task_ids: [first_task.id]
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(first_task.reload.position).to eq(0)
        expect(second_task.reload.position).to eq(1)
      end

      it "配列以外を指定した場合は拒否する" do
        expect do
          described_class.call(
            project: project,
            task_ids: first_task.id
          )
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "不正な形式のIDを指定した場合は拒否する" do
        expect do
          described_class.call(
            project: project,
            task_ids: [first_task.id, "invalid"]
          )
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "親タスクIDが不正な場合" do
      it "存在しない親タスクを指定した場合は拒否する" do
        expect do
          described_class.call(
            project: project,
            parent_task_id: 999_999,
            task_ids: []
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "別プロジェクトのタスクを親に指定した場合は拒否する" do
        another_project = create(:project, team: team)
        another_parent_task = create(:task, project: another_project)

        expect do
          described_class.call(
            project: project,
            parent_task_id: another_parent_task.id,
            task_ids: []
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "サブタスクを親に指定した場合は拒否する" do
        parent_task = create(:task, project: project)
        subtask = create(
          :task,
          project: project,
          parent_task: parent_task
        )

        expect do
          described_class.call(
            project: project,
            parent_task_id: subtask.id,
            task_ids: []
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      before do
        project.update!(archived_at: Time.current)
      end

      it "並び替えを拒否する" do
        task = create(:task, project: project, position: 0)

        expect do
          described_class.call(
            project: project,
            task_ids: [task.id]
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(task.reload.position).to eq(0)
      end
    end
  end
end
