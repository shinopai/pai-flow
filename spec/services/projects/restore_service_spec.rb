# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::RestoreService do
  let(:team) { create(:team) }
  let(:project) do
    create(
      :project,
      team: team,
      archived_at: Time.current
    )
  end

  describe ".call" do
    it "アーカイブ済みプロジェクトを復元できる" do
      described_class.call(project: project)

      expect(project.reload.archived_at).to be_nil
    end

    it "すでに復元済みの場合は何もしない" do
      project.update!(archived_at: nil)

      result = described_class.call(project: project)

      expect(result.reload.archived_at).to be_nil
    end

    it "復元後もプロジェクトと関連データを保持する" do
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
