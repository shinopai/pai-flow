require "rails_helper"

RSpec.describe Teams::TransferOwnershipService do
  describe ".call" do
    it "Ownerを移譲し、移譲元をMemberに変更する" do
      current_owner = create(:team_membership, :owner)
      new_owner = create(
        :team_membership,
        team: current_owner.team,
        role: "member"
      )

      described_class.call(
        team: current_owner.team,
        current_owner:,
        new_owner:
      )

      expect(current_owner.reload.role).to eq("member")
      expect(new_owner.reload.role).to eq("owner")
    end

    it "移譲途中で失敗した場合、両方のroleをロールバックする" do
      current_owner = create(:team_membership, :owner)
      new_owner = create(
        :team_membership,
        team: current_owner.team,
        role: "member"
      )

      service = described_class.new(
        team: current_owner.team,
        current_owner:,
        new_owner:
      )

      allow(service).to receive(:promote_new_owner!)
        .and_raise(ActiveRecord::RecordInvalid.new(new_owner))

      expect { service.call }.to raise_error(ActiveRecord::RecordInvalid)

      expect(current_owner.reload.role).to eq("owner")
      expect(new_owner.reload.role).to eq("member")
    end
  end
end
