# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Memberships", type: :request do
  let(:user) do
    create(:user, confirmed_at: Time.current)
  end

  def sign_in(user)
    post user_session_path,
         params: {
           user: {
             email: user.email,
             password: "password123"
           }
         }
  end

  describe "GET /teams/:team_id/members" do
    context "有効なチーム所属がある場合" do
      it "メンバー一覧を表示できる" do
        team = create(:team)
        create(:team_membership, team: team, user: user, role: "owner")

        sign_in(user)
        get team_members_path(team)

        expect(response).to have_http_status(:ok)
      end
    end

    context "有効なチーム所属がない場合" do
      it "メンバー一覧を表示できず403を返す" do
        team = create(:team)

        sign_in(user)
        get team_members_path(team)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        team = create(:team)

        get team_members_path(team)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /teams/:team_id/members/:id" do
    context "Ownerの場合" do
      %w[member guest].each do |role|
        it "#{role}にロールを変更できる" do
          team = create(:team)
          create(:team_membership, team: team, user: user, role: "owner")

          target_user = create(:user, confirmed_at: Time.current)
          membership = create(
            :team_membership,
            team: team,
            user: target_user,
            role: role == "guest" ? "member" : "guest"
          )

          sign_in(user)

          expect do
            patch team_member_path(team, membership),
                  params: { member: { role: role } }
          end.to change { membership.reload.role }.to(role)

          expect(response).to redirect_to(team_members_path(team))
        end
      end

      it "Ownerには変更できず422を返す" do
        team = create(:team)
        create(:team_membership, team: team, user: user, role: "owner")

        target_user = create(:user, confirmed_at: Time.current)
        membership = create(
          :team_membership,
          team: team,
          user: target_user,
          role: "guest"
        )

        sign_in(user)

        expect do
          patch team_member_path(team, membership),
                params: { member: { role: "owner" } }
        end.not_to(change { membership.reload.role })

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "自身のロールを変更できず422を返す" do
        team = create(:team)
        membership = create(
          :team_membership,
          team: team,
          user: user,
          role: "owner"
        )

        sign_in(user)

        expect do
          patch team_member_path(team, membership),
                params: { member: { role: "member" } }
        end.not_to(change { membership.reload.role })

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "Member・Guestの場合" do
      %w[member guest].each do |role|
        it "#{role}はメンバーのロールを変更できず403を返す" do
          team = create(:team)
          create(:team_membership, team: team, user: user, role: role)

          target_user = create(:user, confirmed_at: Time.current)
          membership = create(
            :team_membership,
            team: team,
            user: target_user,
            role: "guest"
          )

          sign_in(user)

          expect do
            patch team_member_path(team, membership),
                  params: { member: { role: "member" } }
          end.not_to(change { membership.reload.role })

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        team = create(:team)
        membership = create(:team_membership, team: team)

        patch team_member_path(team, membership),
              params: { member: { role: "member" } }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /teams/:team_id/ownership" do
    context "Ownerの場合" do
      it "同じチームのMemberにOwner権限を移譲できる" do
        team = create(:team)
        owner_membership = create(
          :team_membership,
          team: team,
          user: user,
          role: "owner"
        )

        target_user = create(:user, confirmed_at: Time.current)
        target_membership = create(
          :team_membership,
          team: team,
          user: target_user,
          role: "member"
        )

        sign_in(user)

        expect do
          patch team_ownership_path(team),
                params: { ownership: { membership_id: target_membership.id } }
        end.to change { owner_membership.reload.role }
          .from("owner").to("member")
          .and change { target_membership.reload.role }
          .from("member").to("owner")

        expect(response).to redirect_to(team_members_path(team))
      end

      it "GuestにはOwner権限を移譲できない" do
        team = create(:team)
        create(
          :team_membership,
          team: team,
          user: user,
          role: "owner"
        )

        target_user = create(:user, confirmed_at: Time.current)
        target_membership = create(
          :team_membership,
          team: team,
          user: target_user,
          role: "guest"
        )

        sign_in(user)

        patch team_ownership_path(team),
              params: { ownership: { membership_id: target_membership.id } }

        expect(team.team_memberships.find_by!(user: user).role).to eq("owner")
        expect(target_membership.reload.role).to eq("guest")
        expect(response).to redirect_to(team_members_path(team))
        expect(flash[:alert]).to be_present
      end

      it "自身にはOwner権限を移譲できない" do
        team = create(:team)
        owner_membership = create(
          :team_membership,
          team: team,
          user: user,
          role: "owner"
        )

        sign_in(user)

        expect do
          patch team_ownership_path(team),
                params: { ownership: { membership_id: owner_membership.id } }
        end.not_to(change { owner_membership.reload.role })

        expect(response).to redirect_to(team_members_path(team))
        expect(flash[:alert]).to be_present
      end

      it "別のチームのMemberにはOwner権限を移譲できない" do
        team = create(:team)
        create(:team_membership, team: team, user: user, role: "owner")

        another_team = create(:team)
        target_user = create(:user, confirmed_at: Time.current)
        target_membership = create(
          :team_membership,
          team: another_team,
          user: target_user,
          role: "member"
        )

        sign_in(user)

        patch team_ownership_path(team),
              params: { ownership: { membership_id: target_membership.id } }

        expect(response).to have_http_status(:not_found)
      end

      it "存在しないメンバーにはOwner権限を移譲できない" do
        team = create(:team)
        create(:team_membership, team: team, user: user, role: "owner")

        sign_in(user)

        patch team_ownership_path(team),
              params: { ownership: { membership_id: -1 } }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "Member・Guestの場合" do
      %w[member guest].each do |role|
        it "#{role}はOwner権限を移譲できず403を返す" do
          team = create(:team)
          create(:team_membership, team: team, user: user, role: role)

          target_user = create(:user, confirmed_at: Time.current)
          target_membership = create(
            :team_membership,
            team: team,
            user: target_user,
            role: "member"
          )

          sign_in(user)

          patch team_ownership_path(team),
                params: { ownership: { membership_id: target_membership.id } }

          expect(response).to have_http_status(:forbidden)
          expect(target_membership.reload.role).to eq("member")
        end
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        team = create(:team)
        target_user = create(:user, confirmed_at: Time.current)
        target_membership = create(
          :team_membership,
          team: team,
          user: target_user,
          role: "member"
        )

        patch team_ownership_path(team),
              params: { ownership: { membership_id: target_membership.id } }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /teams/:team_id/membership" do
    context "Member・Guestの場合" do
      %w[member guest].each do |role|
        it "#{role}はチームから退出できる" do
          team = create(:team)
          membership = create(
            :team_membership,
            team: team,
            user: user,
            role: role
          )

          sign_in(user)

          expect do
            delete team_membership_path(team)
          end.to change { membership.reload.status }.from("active").to("left")

          expect(membership.reload.left_at).to be_present
          expect(response).to redirect_to(teams_path)
        end
      end
    end

    context "Ownerの場合" do
      it "チームから退出できず、メンバー一覧へリダイレクトする" do
        team = create(:team)
        membership = create(
          :team_membership,
          team: team,
          user: user,
          role: "owner"
        )

        sign_in(user)

        expect do
          delete team_membership_path(team)
        end.not_to(change { membership.reload.status })

        expect(response).to redirect_to(team_members_path(team))
        expect(flash[:alert]).to be_present
      end
    end

    context "有効なチーム所属がない場合" do
      it "チームから退出できず403を返す" do
        team = create(:team)

        sign_in(user)
        delete team_membership_path(team)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        team = create(:team)

        delete team_membership_path(team)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
