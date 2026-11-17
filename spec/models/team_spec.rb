require "rails_helper"

RSpec.describe Team, type: :model do
  describe "validations" do
    it "FactoryBotで有効なTeamを生成できること" do
      team = build(:team)

      expect(team).to be_valid
    end

    it "名前が空の場合は無効であること" do
      team = build(:team, name: nil)

      expect(team).not_to be_valid
      expect(team.errors[:name]).to be_present
    end

    it "名前が100文字を超える場合は無効であること" do
      team = build(:team, name: "あ" * 101)

      expect(team).not_to be_valid
      expect(team.errors[:name]).to be_present
    end
  end

  describe "associations" do
    let!(:team) { create(:team) }

    it "TeamMembershipを複数保持できること" do
      memberships = create_list(:team_membership, 2, team:)

      expect(team.team_memberships).to match_array(memberships)
    end

    it "Projectを複数保持できること" do
      projects = create_list(:project, 2, team:)

      expect(team.projects).to match_array(projects)
    end
  end
end
