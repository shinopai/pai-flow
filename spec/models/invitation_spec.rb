require "rails_helper"

RSpec.describe Invitation, type: :model do
  describe "validations" do
    it "FactoryBotで有効なInvitationを生成できること" do
      invitation = build(:invitation)

      expect(invitation).to be_valid
    end

    it "メールアドレスが空の場合は無効であること" do
      invitation = build(:invitation, email: nil)

      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to be_present
    end

    it "メールアドレスの形式が不正な場合は無効であること" do
      invitation = build(:invitation, email: "invalid-email")

      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to be_present
    end

    it "メールアドレスが255文字を超える場合は無効であること" do
      invitation = build(:invitation, email: "#{"a" * 244}@example.com")

      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to be_present
    end

    it "statusが空の場合は無効であること" do
      invitation = build(:invitation, status: nil)

      expect(invitation).not_to be_valid
      expect(invitation.errors[:status]).to be_present
    end

    it "statusが許可されていない値の場合は無効であること" do
      invitation = build(:invitation, status: "invalid")

      expect(invitation).not_to be_valid
      expect(invitation.errors[:status]).to be_present
    end

    it "pendingの場合にresponded_atが設定されていると無効であること" do
      invitation = build(:invitation, status: "pending", responded_at: Time.current)

      expect(invitation).not_to be_valid
      expect(invitation.errors[:responded_at]).to be_present
    end

    it "pending以外でresponded_atが空の場合は無効であること" do
      invitation = build(:invitation, status: "accepted", responded_at: nil)

      expect(invitation).not_to be_valid
      expect(invitation.errors[:responded_at]).to be_present
    end

    it "pending以外でresponded_atが設定されていれば有効であること" do
      invitation = build(:invitation, status: "accepted", responded_at: Time.current)

      expect(invitation).to be_valid
    end
  end

  describe "associations" do
    it "Teamに所属すること" do
      team = create(:team)
      invitation = create(:invitation, team:)

      expect(invitation.team).to eq(team)
    end

    it "招待先のUserに所属すること" do
      invitee = create(:user)
      invitation = create(:invitation, invitee:)

      expect(invitation.invitee).to eq(invitee)
    end

    it "招待者のUserに所属すること" do
      invited_by = create(:user)
      invitation = create(:invitation, invited_by:)

      expect(invitation.invited_by).to eq(invited_by)
    end
  end
end
