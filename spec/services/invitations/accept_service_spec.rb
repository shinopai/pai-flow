require "rails_helper"

RSpec.describe Invitations::AcceptService do
  let(:user) { create(:user) }
  let(:team) { create(:team, name: "テストチーム") }
  let(:invitation) do
    create(
      :invitation,
      team: team,
      invitee: user,
      invited_by: create(:user),
      email: user.email,
      status: "pending",
      responded_at: nil
    )
  end

  describe ".call" do
    context "招待を承認する場合" do
      it "招待を承認し、Guestとしてチームに所属させる" do
        expect do
          described_class.call(invitation: invitation, user: user)
        end.to change(TeamMembership, :count).by(1)

        expect(invitation.reload).to have_attributes(status: "accepted")
        expect(invitation.responded_at).to be_present

        membership = TeamMembership.find_by!(
          team: team,
          user: user,
          status: "active"
        )

        expect(membership).to have_attributes(
          role: "guest",
          status: "active"
        )
      end
    end

    context "所属レコードの作成に失敗した場合" do
      it "招待の承認もロールバックする" do
        allow_any_instance_of(TeamMembership).to receive(:save!).and_raise(
          ActiveRecord::RecordInvalid.new(TeamMembership.new)
        )

        expect do
          described_class.call(invitation: invitation, user: user)
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(invitation.reload).to have_attributes(
          status: "pending",
          responded_at: nil
        )
        expect(TeamMembership.where(team: team, user: user)).to be_empty
      end
    end
  end
end
