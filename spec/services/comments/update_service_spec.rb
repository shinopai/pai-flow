# frozen_string_literal: true

require "rails_helper"

RSpec.describe Comments::UpdateService do
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
      team_membership: membership,
      body: "変更前のコメント"
    )
  end

  describe ".call" do
    context "投稿者本人の場合" do
      it "コメントを更新する" do
        expect do
          described_class.call(
            comment: comment,
            user: user,
            attributes: { body: "変更後のコメント" }
          )
        end.to change { comment.reload.body }
          .from("変更前のコメント")
          .to("変更後のコメント")
      end
    end

    context "他のユーザーの場合" do
      it "コメントを更新せずエラーを返す" do
        other_user = create(:user)

        expect do
          described_class.call(
            comment: comment,
            user: other_user,
            attributes: { body: "不正な更新" }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(comment.reload.body).to eq("変更前のコメント")
      end
    end

    context "投稿時の所属がleftの場合" do
      before do
        membership.update!(
          status: "left",
          left_at: Time.current
        )
      end

      it "コメントを更新せずエラーを返す" do
        expect do
          described_class.call(
            comment: comment,
            user: user,
            attributes: { body: "不正な更新" }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(comment.reload.body).to eq("変更前のコメント")
      end
    end

    context "投稿時の所属がGuestの場合" do
      before do
        membership.update!(role: "guest")
      end

      it "コメントを更新せずエラーを返す" do
        expect do
          described_class.call(
            comment: comment,
            user: user,
            attributes: { body: "不正な更新" }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(comment.reload.body).to eq("変更前のコメント")
      end
    end

    context "アーカイブ済みプロジェクトの場合" do
      before do
        project.update!(archived_at: Time.current)
      end

      it "コメントを更新せずエラーを返す" do
        expect do
          described_class.call(
            comment: comment,
            user: user,
            attributes: { body: "不正な更新" }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(comment.reload.body).to eq("変更前のコメント")
      end
    end

    context "不正な本文の場合" do
      it "空の本文では更新しない" do
        expect do
          described_class.call(
            comment: comment,
            user: user,
            attributes: { body: "" }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(comment.reload.body).to eq("変更前のコメント")
      end

      it "1000文字を超える本文では更新しない" do
        expect do
          described_class.call(
            comment: comment,
            user: user,
            attributes: { body: "あ" * 1001 }
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        expect(comment.reload.body).to eq("変更前のコメント")
      end
    end
  end
end
