# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let!(:team) { create(:team) }
  let!(:owner) { create(:user, confirmed_at: Time.current) }
  let!(:invitee) { create(:user, confirmed_at: Time.current) }

  before do
    create(:team_membership, team: team, user: owner, role: "owner")
    ActionMailer::Base.deliveries.clear
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

  describe "POST /teams/:team_id/invitations" do
    context "Ownerの場合" do
      it "登録済みユーザーを招待し、招待メールを送信する" do
        sign_in(owner)

        expect do
          post team_invitations_path(team),
               params: { invitation: { email: invitee.email } }
        end.to change(Invitation, :count).by(1)
                                         .and change { ActionMailer::Base.deliveries.count }.by(1)

        invitation = Invitation.last

        expect(invitation.team).to eq(team)
        expect(invitation.invitee).to eq(invitee)
        expect(invitation.invited_by).to eq(owner)
        expect(invitation.email).to eq(invitee.email)
        expect(invitation.status).to eq("pending")
        expect(response).to redirect_to(team_path(team))
        expect(flash[:notice]).to eq("招待メールを送信しました。")

        expect(team.team_memberships.exists?(user: invitee)).to be(false)
      end

      it "登録されていないメールアドレスでは招待を作成しない" do
        sign_in(owner)

        expect do
          post team_invitations_path(team),
               params: { invitation: { email: "unknown@example.com" } }
        end.not_to change(Invitation, :count)

        expect(ActionMailer::Base.deliveries).to be_empty
        expect(response).to redirect_to(team_path(team))
        expect(flash[:alert]).to be_present
      end

      it "すでにチームに所属しているユーザーは招待できない" do
        create(:team_membership, team: team, user: invitee)

        sign_in(owner)

        expect do
          post team_invitations_path(team),
               params: { invitation: { email: invitee.email } }
        end.not_to change(Invitation, :count)

        expect(ActionMailer::Base.deliveries).to be_empty
        expect(response).to redirect_to(team_path(team))
        expect(flash[:alert]).to be_present
      end
    end

    context "Member・Guestの場合" do
      %w[member guest].each do |role|
        it "#{role}は招待できず403を返す" do
          member = create(:user, confirmed_at: Time.current)
          create(:team_membership, team: team, user: member, role: role)

          sign_in(member)

          expect do
            post team_invitations_path(team),
                 params: { invitation: { email: invitee.email } }
          end.not_to change(Invitation, :count)

          expect(ActionMailer::Base.deliveries).to be_empty
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        post team_invitations_path(team),
             params: { invitation: { email: invitee.email } }

        expect(response).to redirect_to(new_user_session_path)
        expect(Invitation.count).to eq(0)
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end

  describe "GET /teams/:team_id/invitations" do
    context "Ownerの場合" do
      it "チームの招待一覧を表示する" do
        create(:invitation, team: team, invited_by: owner, invitee: invitee)

        sign_in(owner)

        get team_invitations_path(team)

        expect(response).to have_http_status(:ok)
      end
    end

    context "Member・Guestの場合" do
      %w[member guest].each do |role|
        it "#{role}は招待一覧を閲覧できず403を返す" do
          member = create(:user, confirmed_at: Time.current)
          create(:team_membership, team: team, user: member, role: role)

          sign_in(member)

          get team_invitations_path(team)

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe "DELETE /teams/:team_id/invitations/:id" do
    let!(:invitation) do
      create(:invitation, team: team, invited_by: owner, invitee: invitee)
    end

    context "Ownerの場合" do
      it "pendingの招待を取り消す" do
        sign_in(owner)

        expect do
          delete team_invitation_path(team, invitation)
        end.to change { invitation.reload.status }
          .from("pending").to("cancelled")

        expect(invitation.reload.responded_at).to be_present
        expect(response).to redirect_to(team_invitations_path(team))
        expect(flash[:notice]).to eq("招待を取り消しました。")
      end

      it "pending以外の招待は取り消せない" do
        invitation.update!(
          status: "accepted",
          responded_at: Time.current
        )

        sign_in(owner)

        expect do
          delete team_invitation_path(team, invitation)
        end.not_to(change { invitation.reload.status })

        expect(response).to redirect_to(team_invitations_path(team))
        expect(flash[:alert]).to be_present
      end

      it "別チームの招待は操作できない" do
        another_team = create(:team)
        another_invitation = create(
          :invitation,
          team: another_team,
          invited_by: owner
        )

        sign_in(owner)

        expect do
          delete team_invitation_path(team, another_invitation)
        end.not_to(change { another_invitation.reload.status })

        expect(response).to have_http_status(:not_found)
      end
    end

    context "Member・Guestの場合" do
      %w[member guest].each do |role|
        it "#{role}は招待を取り消せず403を返す" do
          member = create(:user, confirmed_at: Time.current)
          create(:team_membership, team: team, user: member, role: role)

          sign_in(member)

          expect do
            delete team_invitation_path(team, invitation)
          end.not_to(change { invitation.reload.status })

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
