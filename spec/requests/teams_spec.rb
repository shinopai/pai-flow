# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Teams", type: :request do
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

  describe "GET /teams" do
    context "ログインしている場合" do
      before do
        sign_in(user)
      end

      it "チーム一覧を表示できる" do
        create(:team_membership, user: user)

        get teams_path

        expect(response).to have_http_status(:ok)
      end

      it "初回アクセス時にチームを自動選択しない" do
        create(:team_membership, user: user)

        expect do
          get teams_path
        end.not_to(change { user.reload.last_selected_team_id })
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        get teams_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /teams/:id/select" do
    context "有効なチーム所属がある場合" do
      it "選択したチームを保存してチーム画面へリダイレクトする" do
        team = create(:team)
        create(:team_membership, team: team, user: user)

        sign_in(user)

        expect do
          post select_team_path(team)
        end.to change { user.reload.last_selected_team_id }.from(nil).to(team.id)

        expect(response).to redirect_to(team_path(team))
      end

      it "選択中のチームを別のチームに切り替えられる" do
        current_team = create(:team)
        new_team = create(:team)

        create(:team_membership, team: current_team, user: user)
        create(:team_membership, team: new_team, user: user)

        user.update!(last_selected_team: current_team)

        sign_in(user)

        expect do
          post select_team_path(new_team)
        end.to change { user.reload.last_selected_team_id }
          .from(current_team.id)
          .to(new_team.id)

        expect(response).to redirect_to(team_path(new_team))
      end
    end

    context "有効なチーム所属がない場合" do
      it "チームを選択できず403を返す" do
        team = create(:team)
        sign_in(user)

        expect do
          post select_team_path(team)
        end.not_to(change { user.reload.last_selected_team_id })

        expect(response).to have_http_status(:forbidden)
      end

      it "過去に所属していたチームを選択できない" do
        team = create(:team)
        create(
          :team_membership,
          team: team,
          user: user,
          status: "left",
          left_at: Time.current
        )

        sign_in(user)

        post select_team_path(team)

        expect(response).to have_http_status(:forbidden)
        expect(user.reload.last_selected_team_id).to be_nil
      end
    end
  end

  describe "GET /teams/:id" do
    context "有効なチーム所属がある場合" do
      it "チーム画面を表示できる" do
        team = create(:team)
        create(:team_membership, team: team, user: user)

        sign_in(user)
        get team_path(team)

        expect(response).to have_http_status(:ok)
      end
    end

    context "有効なチーム所属がない場合" do
      it "チーム画面を表示できず403を返す" do
        team = create(:team)

        sign_in(user)
        get team_path(team)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
