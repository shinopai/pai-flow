require "rails_helper"

RSpec.describe "Users::Passwords", type: :request do
  before do
    ActionMailer::Base.deliveries.clear
  end

  let(:user) do
    create(
      :user,
      confirmed_at: Time.current,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def extract_reset_password_token
    mail = ActionMailer::Base.deliveries.last

    mail.body.encoded[/reset_password_token=([^&\s"]+)/, 1]
  end

  describe "GET /users/password/new" do
    it "パスワード再設定メール送信画面を表示できること" do
      get new_user_password_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /users/password" do
    it "登録済みメールアドレス宛てに再設定メールを送信できること" do
      expect do
        post user_password_path,
             params: {
               user: {
                 email: user.email
               }
             }
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(flash[:notice]).to be_present
    end
  end

  describe "GET /users/password/edit" do
    it "有効な再設定トークンで新しいパスワード設定画面を表示できること" do
      user.send_reset_password_instructions
      reset_password_token = extract_reset_password_token

      get edit_user_password_path(
        reset_password_token: reset_password_token
      )

      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /users/password" do
    it "有効なトークンでパスワードを再設定できること" do
      user.send_reset_password_instructions
      reset_password_token = extract_reset_password_token

      patch user_password_path,
            params: {
              user: {
                reset_password_token: reset_password_token,
                password: "newpassword456",
                password_confirmation: "newpassword456"
              }
            }

      expect(response).to redirect_to("/")
      expect(user.reload.valid_password?("newpassword456")).to be(true)
      expect(user.reset_password_token).to be_nil

      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
    end

    it "メール送信から6時間を超えたトークンでは再設定できないこと" do
      user.send_reset_password_instructions
      reset_password_token = extract_reset_password_token

      user.update!(reset_password_sent_at: 7.hours.ago)

      patch user_password_path,
            params: {
              user: {
                reset_password_token: reset_password_token,
                password: "newpassword456",
                password_confirmation: "newpassword456"
              }
            }

      expect(user.reload.valid_password?("password123")).to be(true)
      expect(user.valid_password?("newpassword456")).to be(false)
    end

    it "使用済みの再設定トークンを再利用できないこと" do
      user.send_reset_password_instructions
      reset_password_token = extract_reset_password_token

      patch user_password_path,
            params: {
              user: {
                reset_password_token: reset_password_token,
                password: "newpassword456",
                password_confirmation: "newpassword456"
              }
            }

      expect(user.reload.valid_password?("newpassword456")).to be(true)

      patch user_password_path,
            params: {
              user: {
                reset_password_token: reset_password_token,
                password: "anotherpassword789",
                password_confirmation: "anotherpassword789"
              }
            }

      expect(user.reload.valid_password?("newpassword456")).to be(true)
      expect(user.valid_password?("anotherpassword789")).to be(false)
      expect(flash[:alert]).to be_present
    end
  end

  describe "パスワード再設定後のログイン" do
    it "新しいパスワードでログインできること" do
      user.send_reset_password_instructions
      reset_password_token = extract_reset_password_token

      patch user_password_path,
            params: {
              user: {
                reset_password_token: reset_password_token,
                password: "newpassword456",
                password_confirmation: "newpassword456"
              }
            }

      expect(response).to redirect_to("/")

      delete destroy_user_session_path

      post user_session_path,
           params: {
             user: {
               email: user.email,
               password: "newpassword456"
             }
           }

      expect(response).to redirect_to("/")

      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
    end
  end
end
