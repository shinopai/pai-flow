require "rails_helper"

RSpec.describe TeamMembership, type: :model do
  describe "validations" do
    it "FactoryBotで有効なTeamMembershipを生成できること" do
      membership = build(:team_membership)

      expect(membership).to be_valid
    end

    it "roleが空の場合は無効であること" do
      membership = build(:team_membership, role: nil)

      expect(membership).not_to be_valid
      expect(membership.errors[:role]).to be_present
    end

    it "roleが許可されていない値の場合は無効であること" do
      membership = build(:team_membership, role: "invalid")

      expect(membership).not_to be_valid
      expect(membership.errors[:role]).to be_present
    end

    it "statusが空の場合は無効であること" do
      membership = build(:team_membership, status: nil)

      expect(membership).not_to be_valid
      expect(membership.errors[:status]).to be_present
    end

    it "statusが許可されていない値の場合は無効であること" do
      membership = build(:team_membership, status: "invalid")

      expect(membership).not_to be_valid
      expect(membership.errors[:status]).to be_present
    end

    it "joined_atが空の場合は無効であること" do
      membership = build(:team_membership, joined_at: nil)

      expect(membership).not_to be_valid
      expect(membership.errors[:joined_at]).to be_present
    end

    it "leftの場合にleft_atが空なら無効であること" do
      membership = build(:team_membership, status: "left", left_at: nil)

      expect(membership).not_to be_valid
      expect(membership.errors[:left_at]).to be_present
    end

    it "activeの場合にleft_atが設定されていると無効であること" do
      membership = build(:team_membership, status: "active", left_at: Time.current)

      expect(membership).not_to be_valid
      expect(membership.errors[:left_at]).to be_present
    end

    it "leftの場合にleft_atが設定されていれば有効であること" do
      membership = build(:team_membership, status: "left", left_at: Time.current)

      expect(membership).to be_valid
    end
  end

  describe "associations" do
    it "Teamに所属すること" do
      team = create(:team)
      membership = create(:team_membership, team:)

      expect(membership.team).to eq(team)
    end

    it "Userに所属すること" do
      user = create(:user)
      membership = create(:team_membership, user:)

      expect(membership.user).to eq(user)
    end
  end
end
