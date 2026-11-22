# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects", type: :request do
  let!(:team) { create(:team) }
  let!(:owner) { create(:user, confirmed_at: Time.current) }

  before do
    create(:team_membership, team: team, user: owner, role: "owner")
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

  describe "POST /teams/:team_id/projects" do
    context "Owner・Memberの場合" do
      %w[owner member].each do |role|
        it "#{role}はプロジェクトを作成でき、作成者が初期担当者になる" do
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

          expect do
            post team_projects_path(team),
                 params: {
                   project: {
                     name: "新規プロジェクト",
                     description: "プロジェクトの説明",
                     due_date: "2026-12-31"
                   }
                 }
          end.to change(Project, :count).by(1)

          project = Project.last
          membership = TeamMembership.find_by!(
            team: team,
            user: user,
            status: "active"
          )

          expect(project.team).to eq(team)
          expect(project.created_by).to eq(user)
          expect(project.assignee_membership).to eq(membership)
          expect(project.name).to eq("新規プロジェクト")
          expect(project.description).to eq("プロジェクトの説明")
          expect(project.due_date).to eq(Date.new(2026, 12, 31))
          expect(project.status).to eq("順調")

          expect(response).to redirect_to(team_project_path(team, project))
          expect(flash[:notice]).to eq("プロジェクトを作成しました。")
        end
      end
    end

    context "Guestの場合" do
      it "プロジェクトを作成できず403を返す" do
        guest = create(:user, confirmed_at: Time.current)
        create(:team_membership, team: team, user: guest, role: "guest")

        sign_in(guest)

        expect do
          post team_projects_path(team),
               params: {
                 project: { name: "新規プロジェクト" }
               }
        end.not_to change(Project, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "チームに所属していない場合" do
      it "プロジェクトを作成できず403を返す" do
        user = create(:user, confirmed_at: Time.current)

        sign_in(user)

        expect do
          post team_projects_path(team),
               params: {
                 project: { name: "新規プロジェクト" }
               }
        end.not_to change(Project, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "入力内容が不正な場合" do
      it "プロジェクトを作成せず、エラーを返す" do
        sign_in(owner)

        expect do
          post team_projects_path(team),
               params: {
                 project: { name: "" }
               }
        end.not_to change(Project, :count)

        expect(response).to redirect_to(team_path(team))
        expect(flash[:alert]).to be_present
      end

      it "プロジェクト名が未送信の場合は作成せず、エラーを返す" do
        sign_in(owner)

        expect do
          post team_projects_path(team),
               params: {
                 project: {
                   description: "プロジェクトの説明"
                 }
               }
        end.not_to change(Project, :count)

        expect(response).to redirect_to(team_path(team))
        expect(flash[:alert]).to be_present
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        expect do
          post team_projects_path(team),
               params: {
                 project: { name: "新規プロジェクト" }
               }
        end.not_to change(Project, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
