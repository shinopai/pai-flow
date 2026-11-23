# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::UpdateService do
  let(:team) { create(:team) }
  let(:owner) { create(:user) }
  let(:owner_membership) do
    create(
      :team_membership,
      team: team,
      user: owner,
      role: "owner"
    )
  end
  let(:project) do
    create(
      :project,
      team: team,
      assignee_membership: owner_membership,
      name: "変更前のプロジェクト",
      description: "変更前の説明",
      due_date: Date.new(2026, 12, 31),
      status: "順調"
    )
  end

  describe ".call" do
    context "有効な属性を指定した場合" do
      it "プロジェクト情報を更新できる" do
        updated_project = described_class.call(
          project: project,
          attributes: {
            name: "変更後のプロジェクト",
            description: "変更後の説明",
            due_date: Date.new(2027, 1, 31),
            status: "リスクあり"
          }
        )

        expect(updated_project.name).to eq("変更後のプロジェクト")
        expect(updated_project.description).to eq("変更後の説明")
        expect(updated_project.due_date).to eq(Date.new(2027, 1, 31))
        expect(updated_project.status).to eq("リスクあり")
        expect(updated_project.assignee_membership).to eq(owner_membership)
      end
    end

    context "担当者を変更する場合" do
      it "同じチームのOwnerを担当者に設定できる" do
        project.update!(assignee_membership: nil)

        updated_project = described_class.call(
          project: project,
          attributes: {
            assignee_membership_id: owner_membership.id
          }
        )

        expect(updated_project.assignee_membership).to eq(owner_membership)
      end

      it "同じチームのMemberを担当者に設定できる" do
        member = create(:user)
        membership = create(
          :team_membership,
          team: team,
          user: member,
          role: "member"
        )

        updated_project = described_class.call(
          project: project,
          attributes: {
            assignee_membership_id: membership.id
          }
        )

        expect(updated_project.assignee_membership).to eq(membership)
      end
    end

    context "担当者を解除する場合" do
      it "担当者を未設定にできる" do
        updated_project = described_class.call(
          project: project,
          attributes: {
            assignee_membership_id: ""
          }
        )

        expect(updated_project.assignee_membership).to be_nil
      end
    end

    context "担当者を指定しない場合" do
      it "既存の担当者を維持する" do
        updated_project = described_class.call(
          project: project,
          attributes: {
            name: "変更後のプロジェクト"
          }
        )

        expect(updated_project.name).to eq("変更後のプロジェクト")
        expect(updated_project.assignee_membership).to eq(owner_membership)
      end
    end

    context "不正な担当者を指定した場合" do
      it "Guestを指定すると更新全体を拒否する" do
        guest = create(:user)
        membership = create(
          :team_membership,
          team: team,
          user: guest,
          role: "guest"
        )

        expect do
          described_class.call(
            project: project,
            attributes: {
              name: "更新されてはいけない名前",
              assignee_membership_id: membership.id
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.reload.name).to eq("変更前のプロジェクト")
        expect(project.assignee_membership).to eq(owner_membership)
      end

      it "離脱済みのMemberを指定すると更新全体を拒否する" do
        former_member = create(:user)
        membership = create(
          :team_membership,
          team: team,
          user: former_member,
          role: "member",
          status: "left",
          left_at: Time.current
        )

        expect do
          described_class.call(
            project: project,
            attributes: {
              name: "更新されてはいけない名前",
              assignee_membership_id: membership.id
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.reload.name).to eq("変更前のプロジェクト")
        expect(project.assignee_membership).to eq(owner_membership)
      end

      it "別チームのOwnerを指定すると更新全体を拒否する" do
        another_team = create(:team)
        another_owner = create(:user)
        membership = create(
          :team_membership,
          team: another_team,
          user: another_owner,
          role: "owner"
        )

        expect do
          described_class.call(
            project: project,
            attributes: {
              name: "更新されてはいけない名前",
              assignee_membership_id: membership.id
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.reload.name).to eq("変更前のプロジェクト")
        expect(project.assignee_membership).to eq(owner_membership)
      end

      it "存在しない所属IDを指定すると更新全体を拒否する" do
        expect do
          described_class.call(
            project: project,
            attributes: {
              name: "更新されてはいけない名前",
              assignee_membership_id: -1
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.reload.name).to eq("変更前のプロジェクト")
        expect(project.assignee_membership).to eq(owner_membership)
      end
    end

    context "入力内容が不正な場合" do
      it "プロジェクト名が空の場合は更新しない" do
        expect do
          described_class.call(
            project: project,
            attributes: {
              name: ""
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.reload.name).to eq("変更前のプロジェクト")
      end
    end

    context "アーカイブ済みの場合" do
      it "プロジェクトを更新できない" do
        project.update!(archived_at: Time.current)

        expect do
          described_class.call(
            project: project,
            attributes: {
              name: "更新されてはいけない名前"
            }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(project.reload.name).to eq("変更前のプロジェクト")
      end
    end
  end
end
