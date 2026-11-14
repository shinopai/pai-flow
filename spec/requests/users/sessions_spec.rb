require "rails_helper"

RSpec.describe "Users::Sessions", type: :request do
  describe "POST /users/sign_in" do
    context "認証済みユーザーの場合" do
      let(:user) do
        create(
          :user,
          confirmed_at: Time.current,
          password: "password123",
          password_confirmation: "password123"
        )
      end

      it "ログインに成功し、Welcome画面へ遷移すること" do
        post user_session_path,
             params: {
               user: {
                 email: user.email,
                 password: "password123"
               }
             }

        expect(response).to redirect_to("/")

        get edit_user_registration_path
        expect(response).to have_http_status(:ok)
      end

      it "パスワードが間違っている場合、ログインできないこと" do
        post user_session_path,
             params: {
               user: {
                 email: user.email,
                 password: "wrong_password"
               }
             }

        expect(response).to have_http_status(422)
        expect(flash[:alert]).to be_present
      end
    end

    context "未認証ユーザーの場合" do
      it "ログインできずログイン画面に戻されること" do
        user = create(
          :user,
          confirmed_at: nil,
          password: "password123",
          password_confirmation: "password123"
        )

        post user_session_path,
             params: {
               user: {
                 email: user.email,
                 password: "password123"
               }
             }

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "DELETE /users/sign_out" do
    let(:user) do
      create(
        :user,
        confirmed_at: Time.current,
        password: "password123",
        password_confirmation: "password123"
      )
    end

    before do
      post user_session_path,
           params: {
             user: {
               email: user.email,
               password: "password123"
             }
           }

      expect(response).to redirect_to("/")
    end

    it "ログアウトに成功し、ログイン画面へ遷移すること" do
      delete destroy_user_session_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "ログアウト後は認証が必要なページにアクセスできないこと" do
      delete destroy_user_session_path

      get edit_user_registration_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
