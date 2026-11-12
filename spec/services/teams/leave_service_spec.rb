require "rails_helper"

RSpec.describe Teams::LeaveService do
  describe ".call" do
    context "通常のメンバーの場合" do
      let!(:membership) { create(:team_membership) }

      let!(:project) do
        create(
          :project,
          team: membership.team,
          created_by: membership.user,
          assignee_membership: membership,
          name: "テストプロジェクト",
          status: "順調"
        )
      end

      let!(:task) do
        create(
          :task,
          project:,
          created_by: membership.user,
          assignee_membership: membership,
          title: "テストタスク",
          priority: "high",
          status: "not_started",
          position: 0
        )
      end

      let!(:subtask) do
        create(
          :task,
          project:,
          parent_task: task,
          created_by: membership.user,
          assignee_membership: membership,
          title: "テストサブタスク",
          priority: "medium",
          status: "not_started",
          position: 0
        )
      end

      let!(:comment) do
        create(
          :comment,
          task:,
          team_membership: membership,
          body: "テストコメント"
        )
      end

      it "離脱し、担当者を解除してコメントを保持する" do
        described_class.call(team_membership: membership)

        expect(membership.reload.status).to eq("left")
        expect(membership.left_at).to be_present
        expect(project.reload.assignee_membership_id).to be_nil
        expect(task.reload.assignee_membership_id).to be_nil
        expect(subtask.reload.assignee_membership_id).to be_nil
        expect(comment.reload.team_membership_id).to eq(membership.id)
      end
    end

    it "Ownerの離脱を拒否する" do
      membership = create(:team_membership, :owner)

      expect do
        described_class.call(team_membership: membership)
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(membership.reload.status).to eq("active")
      expect(membership.role).to eq("owner")
    end

    it "離脱処理の途中で失敗した場合、担当者解除をロールバックする" do
      membership = create(:team_membership)

      project = create(
        :project,
        team: membership.team,
        created_by: membership.user,
        assignee_membership: membership,
        name: "テストプロジェクト",
        status: "順調"
      )

      service = described_class.new(team_membership: membership)

      allow(service).to receive(:leave_team!)
        .and_raise(ActiveRecord::RecordInvalid.new(membership))

      expect do
        service.call
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(project.reload.assignee_membership_id).to eq(membership.id)
      expect(membership.reload.status).to eq("active")
      expect(membership.left_at).to be_nil
    end
  end
end
