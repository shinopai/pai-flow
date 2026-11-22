require "rails_helper"

RSpec.describe Invitations::CreateService do
  describe ".call" do
    let!(:team) { create(:team) }
    let!(:owner) { create(:user) }
    let!(:invitee) { create(:user) }

    before do
      create(:team_membership, :owner, team:, user: owner)
      ActionMailer::Base.deliveries.clear
    end

    it "登録済みユーザーを招待し、招待メールを送信する" do
      expect do
        described_class.call(
          team:,
          invited_by: owner,
          email: invitee.email
        )
      end.to change(Invitation, :count).by(1)
                                       .and change { ActionMailer::Base.deliveries.count }.by(1)

      invitation = Invitation.last

      expect(invitation.team).to eq(team)
      expect(invitation.invitee).to eq(invitee)
      expect(invitation.invited_by).to eq(owner)
      expect(invitation.email).to eq(invitee.email)
      expect(invitation.status).to eq("pending")
      expect(invitation).to be_valid

      mail = ActionMailer::Base.deliveries.last

      expect(mail.to).to eq([invitee.email])
      expect(mail.subject).to eq("#{team.name}への招待")

      expect(team.team_memberships.exists?(user: invitee)).to be(false)
    end

    it "登録されていないメールアドレスでは招待を作成しない" do
      expect do
        described_class.call(
          team:,
          invited_by: owner,
          email: "unknown@example.com"
        )
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(Invitation.count).to eq(0)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "すでにチームに所属しているユーザーは招待できない" do
      create(:team_membership, team:, user: invitee)

      expect do
        described_class.call(
          team:,
          invited_by: owner,
          email: invitee.email
        )
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(Invitation.count).to eq(0)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "Owner以外は招待できない" do
      member = create(:user)
      create(:team_membership, team:, user: member)
      ActionMailer::Base.deliveries.clear

      expect do
        described_class.call(
          team:,
          invited_by: member,
          email: invitee.email
        )
      end.to raise_error(Pundit::NotAuthorizedError)

      expect(Invitation.count).to eq(0)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "同じチーム・同じユーザーへのPending招待が存在する場合は招待できない" do
      create(:invitation, team:, invitee:, invited_by: owner)

      expect do
        described_class.call(
          team:,
          invited_by: owner,
          email: invitee.email
        )
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(Invitation.count).to eq(1)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "取消済みの招待が存在する場合は新しい招待を作成できる" do
      previous_invitation = create(
        :invitation,
        team:,
        invitee:,
        invited_by: owner,
        status: "cancelled",
        responded_at: Time.current
      )

      expect do
        described_class.call(
          team:,
          invited_by: owner,
          email: invitee.email
        )
      end.to change(Invitation, :count).by(1)
                                       .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(previous_invitation.reload.status).to eq("cancelled")

      new_invitation = Invitation.order(:created_at).last

      expect(new_invitation.status).to eq("pending")
      expect(new_invitation.invitee).to eq(invitee)
      expect(
        Invitation.where(team:, invitee:, status: "pending").count
      ).to eq(1)
    end

    it "拒否済みの招待が存在する場合は新しい招待を作成できる" do
      previous_invitation = create(
        :invitation,
        team:,
        invitee:,
        invited_by: owner,
        status: "declined",
        responded_at: Time.current
      )

      expect do
        described_class.call(
          team:,
          invited_by: owner,
          email: invitee.email
        )
      end.to change(Invitation, :count).by(1)
                                       .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(previous_invitation.reload.status).to eq("declined")

      new_invitation = Invitation.order(:created_at).last

      expect(new_invitation.status).to eq("pending")
      expect(new_invitation.invitee).to eq(invitee)
      expect(
        Invitation.where(team:, invitee:, status: "pending").count
      ).to eq(1)
    end

    it "Guestとして所属しているユーザーは招待できない" do
      create(:team_membership, :guest, team:, user: invitee)

      expect do
        described_class.call(
          team:,
          invited_by: owner,
          email: invitee.email
        )
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(Invitation.count).to eq(0)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
