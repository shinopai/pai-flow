require "rails_helper"

RSpec.describe "Users::Sessions", type: :request do
  describe "POST /users/sign_in" do
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
end
