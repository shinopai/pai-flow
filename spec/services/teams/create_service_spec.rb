require "rails_helper"

RSpec.describe Teams::CreateService do
  describe ".call" do
    let(:user) { create(:user) }

    context "正常な場合" do
      it "チームと初期Ownerの所属レコードを作成する" do
        team = nil

        expect do
          team = described_class.call(user: user, name: "テストチーム")
        end.to change(Team, :count).by(1)
                                   .and change(TeamMembership, :count).by(1)

        membership = team.team_memberships.find_by!(user: user)

        expect(team.name).to eq("テストチーム")
        expect(membership).to have_attributes(role: "owner", status: "active")
        expect(membership.joined_at).to be_present
      end
    end

    context "所属レコードの作成に失敗した場合" do
      it "チームの作成もロールバックする" do
        expect do
          described_class.call(user: nil, name: "テストチーム")
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(Team.count).to eq(0)
        expect(TeamMembership.count).to eq(0)
      end
    end
  end
end
