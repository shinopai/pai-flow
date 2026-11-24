# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::DestroyService do
  describe ".call" do
    let!(:project) { create(:project) }
    let!(:task) { create(:task, project:) }
    let!(:subtask) do
      create(:task, project:, parent_task_id: task.id)
    end
    let!(:task_comment) { create(:comment, task:) }
    let!(:subtask_comment) { create(:comment, task: subtask) }

    it "プロジェクトと配下のタスク・サブタスク・コメントを完全削除する" do
      expect do
        described_class.call(project:)
      end.to change(Project, :count).by(-1)
                                    .and change(Task, :count).by(-2)
                                                             .and change(Comment, :count).by(-2)

      expect(Project.exists?(project.id)).to be false
      expect(Task.exists?(task.id)).to be false
      expect(Task.exists?(subtask.id)).to be false
      expect(Comment.exists?(task_comment.id)).to be false
      expect(Comment.exists?(subtask_comment.id)).to be false
    end

    it "アーカイブ済みプロジェクトも完全削除する" do
      project.update!(archived_at: Time.current)

      expect do
        described_class.call(project:)
      end.to change(Project, :count).by(-1)

      expect(Project.exists?(project.id)).to be false
    end
  end
end
