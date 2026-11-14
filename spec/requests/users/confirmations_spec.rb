require "rails_helper"

RSpec.describe "Users::Confirmations", type: :request do
  before do
    ActionMailer::Base.deliveries.clear
  end

  describe "GET /users/confirmation/new" do
    it "確認メール再送画面を表示できること" do
      get new_user_confirmation_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /users/confirmation" do
    it "有効な確認リンクにアクセスするとユーザーが認証されること" do
      user = create(:user, confirmed_at: nil)
      user.send_confirmation_instructions

      mail = ActionMailer::Base.deliveries.last
      confirmation_token = mail.body.encoded.match(
        /confirmation_token=([^&\s"]+)/
      )[1]

      expect do
        get user_confirmation_path(
          confirmation_token: confirmation_token
        )
      end.to change { user.reload.confirmed_at }.from(nil)
    end

    it "確認メールの送信から3日を超えた確認リンクでは認証されないこと" do
      user = create(:user, confirmed_at: nil)
      user.send_confirmation_instructions

      mail = ActionMailer::Base.deliveries.last
      confirmation_token = mail.body.encoded.match(
        /confirmation_token=([^&\s"]+)/
      )[1]

      user.update!(confirmation_sent_at: 4.days.ago)

      get user_confirmation_path(
        confirmation_token: confirmation_token
      )

      expect(user.reload.confirmed_at).to be_nil
    end
  end

  describe "POST /users/confirmation" do
    context "未認証ユーザーの場合" do
      it "確認メールを再送できること" do
        user = create(:user, confirmed_at: nil)
        user.update!(
          confirmation_instructions_sent_at: 2.minutes.ago
        )

        expect do
          post user_confirmation_path,
               params: { user: { email: user.email } }
        end.to change { ActionMailer::Base.deliveries.size }.by(1)

        expect(user.reload.confirmation_instructions_sent_at)
          .to be_within(1.second).of(Time.current)
      end

      it "前回送信から60秒未満の場合は再送できないこと" do
        user = create(:user, confirmed_at: nil)
        previous_sent_at = 30.seconds.ago
        user.update!(
          confirmation_instructions_sent_at: previous_sent_at
        )

        expect do
          post user_confirmation_path,
               params: { user: { email: user.email } }
        end.not_to(change { ActionMailer::Base.deliveries.size })

        expect(user.reload.confirmation_instructions_sent_at)
          .to be_within(1.second).of(previous_sent_at)
      end

      it "前回送信から60秒以上経過すれば再送できること" do
        user = create(:user, confirmed_at: nil)
        user.update!(
          confirmation_instructions_sent_at: 60.seconds.ago
        )

        expect do
          post user_confirmation_path,
               params: { user: { email: user.email } }
        end.to change { ActionMailer::Base.deliveries.size }.by(1)

        expect(user.reload.confirmation_instructions_sent_at)
          .to be_within(1.second).of(Time.current)
      end
    end

    context "認証済みユーザーの場合" do
      it "確認メールを再送できないこと" do
        user = create(:user, confirmed_at: Time.current)
        previous_sent_at = 2.minutes.ago
        user.update!(
          confirmation_instructions_sent_at: previous_sent_at
        )

        expect do
          post user_confirmation_path,
               params: { user: { email: user.email } }
        end.not_to(change { ActionMailer::Base.deliveries.size })

        expect(user.reload.confirmation_instructions_sent_at)
          .to be_within(1.second).of(previous_sent_at)
      end
    end
  end
end
