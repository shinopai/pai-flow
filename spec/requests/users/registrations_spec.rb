require "rails_helper"

RSpec.describe "Users::Registrations", type: :request do
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

    ActionMailer::Base.deliveries.clear
  end

  describe "PATCH /users" do
    context "名前の変更" do
      it "名前の変更に成功すること" do
        patch user_registration_path,
              params: {
                user: {
                  name: "変更後の名前",
                  current_password: "password123"
                }
              }

        expect(response).to redirect_to("/")
        expect(user.reload.name).to eq("変更後の名前")
      end
    end

    context "メールアドレスの変更" do
      it "確認メールが送信され、認証前は旧メールアドレスが有効であること" do
        old_email = user.email
        new_email = "new@example.com"

        patch user_registration_path,
              params: {
                user: {
                  email: new_email,
                  current_password: "password123"
                }
              }

        user.reload

        expect(response).to redirect_to("/")
        expect(user.email).to eq(old_email)
        expect(user.unconfirmed_email).to eq(new_email)
        expect(ActionMailer::Base.deliveries.size).to eq(1)
        expect(ActionMailer::Base.deliveries.last.to).to include(new_email)
      end

      it "確認メールの認証後、新しいメールアドレスが有効になること" do
        new_email = "new@example.com"

        patch user_registration_path,
              params: {
                user: {
                  email: new_email,
                  current_password: "password123"
                }
              }

        mail = ActionMailer::Base.deliveries.last
        token = mail.body.encoded[/confirmation_token=([^&\s"]+)/, 1]

        expect(token).to be_present

        get user_confirmation_path(confirmation_token: token)

        expect(response).to redirect_to("/")
        expect(user.reload.email).to eq(new_email)
        expect(user.unconfirmed_email).to be_nil
      end
    end

    context "パスワードの変更" do
      it "パスワードの変更に成功すること" do
        patch user_registration_path,
              params: {
                user: {
                  password: "newpassword123",
                  password_confirmation: "newpassword123",
                  current_password: "password123"
                }
              }

        expect(response).to redirect_to("/")
        expect(user.reload.valid_password?("newpassword123")).to be(true)
        expect(user.valid_password?("password123")).to be(false)
      end
    end

    context "入力内容が不正な場合" do
      it "現在のパスワードが間違っている場合、変更できないこと" do
        patch user_registration_path,
              params: {
                user: {
                  name: "変更後の名前",
                  current_password: "wrong_password"
                }
              }

        expect(response).to have_http_status(422)
        expect(user.reload.name).not_to eq("変更後の名前")
      end

      it "現在のパスワードが未入力の場合、変更できないこと" do
        patch user_registration_path,
              params: {
                user: {
                  name: "変更後の名前"
                }
              }

        expect(response).to have_http_status(422)
        expect(user.reload.name).not_to eq("変更後の名前")
      end

      it "パスワード確認が一致しない場合、変更できないこと" do
        patch user_registration_path,
              params: {
                user: {
                  password: "newpassword123",
                  password_confirmation: "different_password",
                  current_password: "password123"
                }
              }

        expect(response).to have_http_status(422)
        expect(user.reload.valid_password?("password123")).to be(true)
      end

      it "名前が未入力の場合、変更できないこと" do
        patch user_registration_path,
              params: {
                user: {
                  name: "",
                  current_password: "password123"
                }
              }

        expect(response).to have_http_status(422)
        expect(user.reload.name).not_to be_blank
      end
    end
  end
end
