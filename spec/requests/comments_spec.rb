# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Comments", type: :request do
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

  let!(:project) do
    create(
      :project,
      team: team,
      created_by: owner,
      assignee_membership: owner_membership
    )
  end

  let!(:task) { create(:task, project: project) }
  let!(:subtask) do
    create(:task, project: project, parent_task_id: task.id)
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

  describe "POST /teams/:team_id/projects/:project_id/tasks/:task_id/comments" do
    context "Owner・Memberの場合" do
      %w[owner member].each do |role|
        it "#{role}はタスクにコメントを投稿できる" do
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
            post team_project_task_comments_path(team, project, task),
                 params: { comment: { body: "テストコメント" } }
          end.to change(Comment, :count).by(1)

          comment = Comment.last

          expect(comment.body).to eq("テストコメント")
          expect(comment.task).to eq(task)
          expect(comment.team_membership.user).to eq(user)
          expect(response).to redirect_to(team_project_path(team, project))
          expect(flash[:notice]).to eq("コメントを投稿しました。")
        end
      end

      it "サブタスクにもコメントを投稿できる" do
        sign_in(owner)

        expect do
          post team_project_task_comments_path(team, project, subtask),
               params: { comment: { body: "サブタスクへのコメント" } }
        end.to change(Comment, :count).by(1)

        expect(Comment.last.task).to eq(subtask)
        expect(response).to redirect_to(team_project_path(team, project))
      end
    end

    context "Guestの場合" do
      it "コメントを投稿できず403を返す" do
        guest = create(:user, confirmed_at: Time.current)
        create(
          :team_membership,
          team: team,
          user: guest,
          role: "guest"
        )

        sign_in(guest)

        expect do
          post team_project_task_comments_path(team, project, task),
               params: { comment: { body: "テストコメント" } }
        end.not_to change(Comment, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "チームに所属していない場合" do
      it "コメントを投稿できず403を返す" do
        user = create(:user, confirmed_at: Time.current)

        sign_in(user)

        expect do
          post team_project_task_comments_path(team, project, task),
               params: { comment: { body: "テストコメント" } }
        end.not_to change(Comment, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      it "コメントを投稿できず403を返す" do
        project.update!(archived_at: Time.current)

        sign_in(owner)

        expect do
          post team_project_task_comments_path(team, project, task),
               params: { comment: { body: "テストコメント" } }
        end.not_to change(Comment, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "不正な本文の場合" do
      it "空の本文では投稿できない" do
        sign_in(owner)

        expect do
          post team_project_task_comments_path(team, project, task),
               params: { comment: { body: "" } }
        end.not_to change(Comment, :count)

        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:alert]).to be_present
      end

      it "1000文字を超える本文では投稿できない" do
        sign_in(owner)

        expect do
          post team_project_task_comments_path(team, project, task),
               params: { comment: { body: "あ" * 1001 } }
        end.not_to change(Comment, :count)

        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:alert]).to be_present
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトする" do
        expect do
          post team_project_task_comments_path(team, project, task),
               params: { comment: { body: "テストコメント" } }
        end.not_to change(Comment, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /teams/:team_id/projects/:project_id/tasks/:task_id/comments/:id" do
    let!(:comment) do
      create(
        :comment,
        task: task,
        team_membership: owner_membership,
        body: "変更前のコメント"
      )
    end

    context "投稿者本人の場合" do
      it "コメントを更新する" do
        sign_in(owner)

        patch team_project_task_comment_path(team, project, task, comment),
              params: { comment: { body: "変更後のコメント" } }

        expect(comment.reload.body).to eq("変更後のコメント")
        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:notice]).to eq("コメントを更新しました。")
      end
    end

    context "他のユーザーの場合" do
      it "コメントを更新できず403を返す" do
        other_user = create(:user, confirmed_at: Time.current)
        create(:team_membership, team: team, user: other_user, role: "member")

        sign_in(other_user)

        patch team_project_task_comment_path(team, project, task, comment),
              params: { comment: { body: "不正な更新" } }

        expect(response).to have_http_status(:forbidden)
        expect(comment.reload.body).to eq("変更前のコメント")
      end
    end

    context "Guestの場合" do
      it "コメントを更新できず403を返す" do
        owner_membership.update!(role: "guest")

        sign_in(owner)

        patch team_project_task_comment_path(team, project, task, comment),
              params: { comment: { body: "不正な更新" } }

        expect(response).to have_http_status(:forbidden)
        expect(comment.reload.body).to eq("変更前のコメント")
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      it "コメントを更新できず403を返す" do
        project.update!(archived_at: Time.current)

        sign_in(owner)

        patch team_project_task_comment_path(team, project, task, comment),
              params: { comment: { body: "不正な更新" } }

        expect(response).to have_http_status(:forbidden)
        expect(comment.reload.body).to eq("変更前のコメント")
      end
    end

    context "別タスクのコメントIDを指定した場合" do
      it "コメントを取得できず404を返す" do
        another_task = create(:task, project: project)
        another_comment = create(
          :comment,
          task: another_task,
          team_membership: owner_membership
        )

        sign_in(owner)

        patch team_project_task_comment_path(team, project, task, another_comment)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /teams/:team_id/projects/:project_id/tasks/:task_id/comments/:id" do
    let!(:comment) do
      create(
        :comment,
        task: task,
        team_membership: owner_membership
      )
    end

    context "投稿者本人の場合" do
      it "コメントを削除する" do
        sign_in(owner)

        expect do
          delete team_project_task_comment_path(team, project, task, comment)
        end.to change(Comment, :count).by(-1)

        expect(response).to redirect_to(team_project_path(team, project))
        expect(flash[:notice]).to eq("コメントを削除しました。")
      end
    end

    context "他のユーザーの場合" do
      it "コメントを削除できず403を返す" do
        other_user = create(:user, confirmed_at: Time.current)
        create(:team_membership, team: team, user: other_user, role: "member")

        sign_in(other_user)

        expect do
          delete team_project_task_comment_path(team, project, task, comment)
        end.not_to change(Comment, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "Guestの場合" do
      it "コメントを削除できず403を返す" do
        owner_membership.update!(role: "guest")

        sign_in(owner)

        expect do
          delete team_project_task_comment_path(team, project, task, comment)
        end.not_to change(Comment, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      it "コメントを削除できず403を返す" do
        project.update!(archived_at: Time.current)

        sign_in(owner)

        expect do
          delete team_project_task_comment_path(team, project, task, comment)
        end.not_to change(Comment, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "別タスクのコメントIDを指定した場合" do
      it "コメントを取得できず404を返す" do
        another_task = create(:task, project: project)
        another_comment = create(
          :comment,
          task: another_task,
          team_membership: owner_membership
        )

        sign_in(owner)

        expect do
          delete team_project_task_comment_path(team, project, task, another_comment)
        end.not_to change(Comment, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
