# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Projects", type: :request do
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
      assignee_membership: owner_membership,
      name: "変更前のプロジェクト",
      description: "変更前の説明",
      due_date: Date.new(2026, 12, 31),
      status: "順調"
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

  describe "GET /teams/:team_id/projects" do
    context "Owner・Member・Guestの場合" do
      %w[owner member guest].each do |role|
        it "#{role}はプロジェクト一覧を取得できる" do
          user = if role == "owner"
                   owner
                 else
                   member = create(:user, confirmed_at: Time.current)
                   create(
                     :team_membership,
                     team: team,
                     user: member,
                     role: role
                   )
                   member
                 end

          sign_in(user)

          get team_projects_path(team)

          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "チームに所属していない場合" do
      it "プロジェクト一覧を取得できず403を返す" do
        user = create(:user, confirmed_at: Time.current)

        sign_in(user)

        get team_projects_path(team)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        get team_projects_path(team)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "検索条件を指定した場合" do
      it "検索条件をListServiceに渡す" do
        sign_in(owner)

        filters = {
          keyword: "プロジェクト",
          status: "順調",
          assignee_id: "unassigned",
          due_date_from: "2026-12-01",
          due_date_to: "2026-12-31",
          sort: "due_date"
        }

        expect(Projects::ListService).to receive(:call).with(
          team: team,
          filters: filters
        ).and_call_original

        get team_projects_path(team), params: filters

        expect(response).to have_http_status(:ok)
      end
    end

    context "期限の指定が不正な場合" do
      it "開始日が終了日より後なら422を返す" do
        sign_in(owner)

        get team_projects_path(team),
            params: {
              due_date_from: "2027-01-01",
              due_date_to: "2026-12-31"
            }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
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

          created_project = Project.last
          membership = TeamMembership.find_by!(
            team: team,
            user: user,
            status: "active"
          )

          expect(created_project.team).to eq(team)
          expect(created_project.created_by).to eq(user)
          expect(created_project.assignee_membership).to eq(membership)
          expect(created_project.name).to eq("新規プロジェクト")
          expect(created_project.description).to eq("プロジェクトの説明")
          expect(created_project.due_date).to eq(Date.new(2026, 12, 31))
          expect(created_project.status).to eq("順調")

          expect(response).to redirect_to(
            team_project_path(team, created_project)
          )
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

  describe "PATCH /teams/:team_id/projects/:id" do
    context "Ownerの場合" do
      it "プロジェクト情報を更新できる" do
        sign_in(owner)

        patch team_project_path(team, project),
              params: {
                project: {
                  name: "変更後のプロジェクト",
                  description: "変更後の説明",
                  due_date: "2027-01-31",
                  status: "リスクあり"
                }
              }

        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:notice]).to eq("プロジェクトを更新しました。")

        project.reload

        expect(project.name).to eq("変更後のプロジェクト")
        expect(project.description).to eq("変更後の説明")
        expect(project.due_date).to eq(Date.new(2027, 1, 31))
        expect(project.status).to eq("リスクあり")
      end

      it "同じチームのMemberに担当者を変更できる" do
        member = create(:user)
        membership = create(
          :team_membership,
          team: team,
          user: member,
          role: "member"
        )

        sign_in(owner)

        patch team_project_path(team, project),
              params: {
                project: {
                  assignee_membership_id: membership.id
                }
              }

        expect(response).to redirect_to(team_project_path(team, project))
        expect(project.reload.assignee_membership).to eq(membership)
      end
    end

    context "Memberの場合" do
      it "プロジェクト情報を更新できる" do
        member = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: member,
          role: "member"
        )

        sign_in(member)

        patch team_project_path(team, project),
              params: {
                project: {
                  name: "Memberによる更新"
                }
              }

        expect(response).to redirect_to(team_project_path(team, project))
        expect(project.reload.name).to eq("Memberによる更新")
      end
    end

    context "Guestの場合" do
      it "プロジェクトを更新できず403を返す" do
        guest = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: guest,
          role: "guest"
        )

        sign_in(guest)

        patch team_project_path(team, project),
              params: {
                project: {
                  name: "更新されてはいけない名前"
                }
              }

        expect(response).to have_http_status(:forbidden)
        expect(project.reload.name).to eq("変更前のプロジェクト")
      end
    end

    context "チームに所属していない場合" do
      it "プロジェクトを更新できず403を返す" do
        user = create(:user, confirmed_at: Time.current)

        sign_in(user)

        patch team_project_path(team, project),
              params: {
                project: {
                  name: "更新されてはいけない名前"
                }
              }

        expect(response).to have_http_status(:forbidden)
        expect(project.reload.name).to eq("変更前のプロジェクト")
      end
    end

    context "別チームのプロジェクトを指定した場合" do
      it "プロジェクトを取得できず404を返す" do
        another_team = create(:team)
        another_project = create(
          :project,
          team: another_team,
          created_by: owner
        )

        sign_in(owner)

        patch team_project_path(team, another_project),
              params: {
                project: {
                  name: "更新されてはいけない名前"
                }
              }

        expect(response).to have_http_status(:not_found)
        expect(another_project.reload.name).to eq("テストプロジェクト")
      end
    end

    context "担当者の指定が不正な場合" do
      it "Guestを指定すると更新全体を拒否する" do
        guest = create(:user)
        membership = create(
          :team_membership,
          team: team,
          user: guest,
          role: "guest"
        )

        sign_in(owner)

        patch team_project_path(team, project),
              params: {
                project: {
                  name: "更新されてはいけない名前",
                  assignee_membership_id: membership.id
                }
              }

        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:alert]).to be_present
        expect(project.reload.name).to eq("変更前のプロジェクト")
        expect(project.assignee_membership).to eq(owner_membership)
      end
    end

    context "入力内容が不正な場合" do
      it "プロジェクト名が空の場合は更新せずエラーを返す" do
        sign_in(owner)

        patch team_project_path(team, project),
              params: {
                project: {
                  name: ""
                }
              }

        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:alert]).to be_present
        expect(project.reload.name).to eq("変更前のプロジェクト")
      end
    end

    context "アーカイブ済みの場合" do
      it "プロジェクトを更新できず403を返す" do
        project.update!(archived_at: Time.current)

        sign_in(owner)

        patch team_project_path(team, project),
              params: {
                project: {
                  name: "更新されてはいけない名前"
                }
              }

        expect(response).to have_http_status(:forbidden)
        expect(project.reload.name).to eq("変更前のプロジェクト")
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        patch team_project_path(team, project),
              params: {
                project: {
                  name: "更新されてはいけない名前"
                }
              }

        expect(response).to redirect_to(new_user_session_path)
        expect(project.reload.name).to eq("変更前のプロジェクト")
      end
    end
  end
end
