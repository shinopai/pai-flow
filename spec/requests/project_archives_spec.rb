# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project archives", type: :request do
  let!(:team) { create(:team) }
  let!(:owner) { create(:user, confirmed_at: Time.current) }
  let!(:owner_membership) do
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
      created_by: owner,
      assignee_membership: owner_membership
    )
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

  describe "PATCH /teams/:team_id/projects/:id/archive" do
    context "Owner・Memberの場合" do
      %w[owner member].each do |role|
        it "#{role}はプロジェクトをアーカイブできる" do
          user = if role == "owner"
                   owner
                 else
                   member = create(:user, confirmed_at: Time.current)
                   create(
                     :team_membership,
                     team: team,
                     user: member,
                     role: "member"
                   )
                   member
                 end

          sign_in(user)

          patch archive_team_project_path(team, project)

          expect(response).to redirect_to(team_path(team))
          expect(flash[:notice]).to eq(
            "プロジェクトをアーカイブしました。"
          )
          expect(project.reload.archived_at).to be_present
        end
      end
    end

    context "Guestの場合" do
      it "アーカイブできず403を返す" do
        guest = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: guest,
          role: "guest"
        )

        sign_in(guest)

        patch archive_team_project_path(team, project)

        expect(response).to have_http_status(:forbidden)
        expect(project.reload.archived_at).to be_nil
      end
    end

    context "チームに所属していない場合" do
      it "アーカイブできず403を返す" do
        user = create(:user, confirmed_at: Time.current)

        sign_in(user)

        patch archive_team_project_path(team, project)

        expect(response).to have_http_status(:forbidden)
        expect(project.reload.archived_at).to be_nil
      end
    end

    context "別チームのプロジェクトを指定した場合" do
      it "アーカイブできず404を返す" do
        another_team = create(:team)
        another_project = create(
          :project,
          team: another_team,
          created_by: owner
        )

        sign_in(owner)

        patch archive_team_project_path(team, another_project)

        expect(response).to have_http_status(:not_found)
        expect(another_project.reload.archived_at).to be_nil
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        patch archive_team_project_path(team, project)

        expect(response).to redirect_to(new_user_session_path)
        expect(project.reload.archived_at).to be_nil
      end
    end
  end

  describe "PATCH /teams/:team_id/projects/:id/restore" do
    before do
      project.update!(archived_at: Time.current)
    end

    context "Owner・Memberの場合" do
      %w[owner member].each do |role|
        it "#{role}はプロジェクトを復元できる" do
          user = if role == "owner"
                   owner
                 else
                   member = create(:user, confirmed_at: Time.current)
                   create(
                     :team_membership,
                     team: team,
                     user: member,
                     role: "member"
                   )
                   member
                 end

          sign_in(user)

          patch restore_team_project_path(team, project)

          expect(response).to redirect_to(team_project_path(team, project))
          expect(flash[:notice]).to eq(
            "プロジェクトを復元しました。"
          )
          expect(project.reload.archived_at).to be_nil
        end
      end
    end

    context "Guestの場合" do
      it "復元できず403を返す" do
        guest = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: guest,
          role: "guest"
        )

        sign_in(guest)

        patch restore_team_project_path(team, project)

        expect(response).to have_http_status(:forbidden)
        expect(project.reload.archived_at).to be_present
      end
    end

    context "チームに所属していない場合" do
      it "復元できず403を返す" do
        user = create(:user, confirmed_at: Time.current)

        sign_in(user)

        patch restore_team_project_path(team, project)

        expect(response).to have_http_status(:forbidden)
        expect(project.reload.archived_at).to be_present
      end
    end

    context "別チームのプロジェクトを指定した場合" do
      it "復元できず404を返す" do
        another_team = create(:team)
        another_project = create(
          :project,
          team: another_team,
          created_by: owner,
          archived_at: Time.current
        )

        sign_in(owner)

        patch restore_team_project_path(team, another_project)

        expect(response).to have_http_status(:not_found)
        expect(another_project.reload.archived_at).to be_present
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        patch restore_team_project_path(team, project)

        expect(response).to redirect_to(new_user_session_path)
        expect(project.reload.archived_at).to be_present
      end
    end
  end
end
