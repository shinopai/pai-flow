# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::ArchiveService do
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team) }

  describe ".call" do
    it "プロジェクトをアーカイブできる" do
      described_class.call(project: project)

      expect(project.reload.archived_at).to be_present
    end

    it "すでにアーカイブ済みの場合は日時を変更しない" do
      archived_at = 1.day.ago
      project.update!(archived_at: archived_at)

      described_class.call(project: project)

      expect(project.reload.archived_at).to be_within(1.second).of(archived_at)
    end

    it "アーカイブ後もプロジェクトと関連データを保持する" do
      task = create(:task, project: project)

      described_class.call(project: project)

      expect(Project.exists?(project.id)).to be(true)
      expect(Task.exists?(task.id)).to be(true)
    end

    it "プロジェクトを返す" do
      result = described_class.call(project: project)

      expect(result).to eq(project)
    end
  end
end
