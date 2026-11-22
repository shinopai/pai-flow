require "rails_helper"

RSpec.describe Invitations::DeclineService do
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
    context "招待を拒否する場合" do
      it "招待を拒否し、responded_atを設定する" do
        expect do
          described_class.call(invitation: invitation, user: user)
        end.not_to change(TeamMembership, :count)

        expect(invitation.reload).to have_attributes(status: "declined")
        expect(invitation.responded_at).to be_present
      end
    end

    context "招待対象者以外が拒否しようとした場合" do
      it "拒否せず、招待状態を維持する" do
        other_user = create(:user)

        expect do
          expect do
            described_class.call(invitation: invitation, user: other_user)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end.not_to change(TeamMembership, :count)

        expect(invitation.reload).to have_attributes(
          status: "pending",
          responded_at: nil
        )
      end
    end

    context "登録メールアドレスが招待メールアドレスと一致しない場合" do
      it "拒否せず、招待状態を維持する" do
        invitation.update_column(:email, "other@example.com")

        expect do
          described_class.call(invitation: invitation, user: user)
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(invitation.reload).to have_attributes(
          status: "pending",
          responded_at: nil
        )
      end
    end

    context "招待がpending以外の場合" do
      it "拒否せず、招待状態を維持する" do
        invitation.update!(
          status: "cancelled",
          responded_at: Time.current
        )

        expect do
          described_class.call(invitation: invitation, user: user)
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(invitation.reload.status).to eq("cancelled")
      end
    end
  end
end
