# frozen_string_literal: true

require "rails_helper"

RSpec.describe Comments::DestroyService do
  let(:team) { create(:team) }
  let(:user) { create(:user) }
  let(:membership) do
    create(:team_membership, team: team, user: user, role: "owner")
  end
  let(:project) { create(:project, team: team) }
  let(:task) { create(:task, project: project) }
  let(:comment) do
    create(
      :comment,
      task: task,
      team_membership: membership
    )
  end

  describe ".call" do
    context "投稿者本人の場合" do
      it "コメントを削除する" do
        comment_id = comment.id

        expect do
          described_class.call(comment: comment, user: user)
        end.to change(Comment, :count).by(-1)

        expect(Comment.exists?(comment_id)).to be(false)
      end
    end

    context "他のユーザーの場合" do
      it "コメントを削除せずエラーを返す" do
        other_user = create(:user)

        expect do
          described_class.call(comment: comment, user: other_user)
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(Comment.exists?(comment.id)).to be(true)
      end
    end

    context "投稿時の所属がleftの場合" do
      before do
        membership.update!(
          status: "left",
          left_at: Time.current
        )
      end

      it "コメントを削除せずエラーを返す" do
        expect do
          described_class.call(comment: comment, user: user)
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(Comment.exists?(comment.id)).to be(true)
      end
    end

    context "投稿時の所属がGuestの場合" do
      before do
        membership.update!(role: "guest")
      end

      it "コメントを削除せずエラーを返す" do
        expect do
          described_class.call(comment: comment, user: user)
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(Comment.exists?(comment.id)).to be(true)
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      before do
        project.update!(archived_at: Time.current)
      end

      it "コメントを削除せずエラーを返す" do
        expect do
          described_class.call(comment: comment, user: user)
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(Comment.exists?(comment.id)).to be(true)
      end
    end
  end
end
