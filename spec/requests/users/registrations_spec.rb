require "rails_helper"

RSpec.describe "ユーザー登録", type: :request do
  before do
    ActionMailer::Base.deliveries.clear
  end

  describe "POST /users" do
    it "有効な情報でユーザーを登録し、確認メールを送信すること" do
      expect do
        post user_registration_path, params: {
          user: {
            name: "テストユーザー",
            email: "TEST@EXAMPLE.COM",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end.to change(User, :count).by(1)

      user = User.last

      expect(user.name).to eq("テストユーザー")
      expect(user.email).to eq("test@example.com")
      expect(user.confirmed_at).to be_nil

      expect(response).to have_http_status(:redirect)

      expect(flash[:notice]).to eq(
        I18n.t("devise.registrations.signed_up_but_unconfirmed")
      )

      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "名前が未入力の場合は登録されないこと" do
      expect do
        post user_registration_path, params: {
          user: {
            name: nil,
            email: "test@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end.not_to change(User, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "メールアドレスが未入力の場合は登録されないこと" do
      expect do
        post user_registration_path, params: {
          user: {
            name: "テストユーザー",
            email: nil,
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end.not_to change(User, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "登録済みのメールアドレスでは登録されないこと" do
      existing_user = create(:user)
      ActionMailer::Base.deliveries.clear

      expect do
        post user_registration_path, params: {
          user: {
            name: "別のテストユーザー",
            email: existing_user.email.upcase,
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end.not_to change(User, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "パスワードが未入力の場合は登録されないこと" do
      expect do
        post user_registration_path, params: {
          user: {
            name: "テストユーザー",
            email: "password-missing@example.com",
            password: nil,
            password_confirmation: nil
          }
        }
      end.not_to change(User, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "パスワード確認が未入力の場合は登録されないこと" do
      expect do
        post user_registration_path, params: {
          user: {
            name: "テストユーザー",
            email: "confirmation-missing@example.com",
            password: "password123",
            password_confirmation: nil
          }
        }
      end.not_to change(User, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "パスワードとパスワード確認が一致しない場合は登録されないこと" do
      expect do
        post user_registration_path, params: {
          user: {
            name: "テストユーザー",
            email: "mismatch@example.com",
            password: "password123",
            password_confirmation: "different123"
          }
        }
      end.not_to change(User, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "不正な形式のメールアドレスでは登録されないこと" do
      expect do
        post user_registration_path, params: {
          user: {
            name: "テストユーザー",
            email: "invalid-email",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end.not_to change(User, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "8文字未満のパスワードでは登録されないこと" do
      expect do
        post user_registration_path, params: {
          user: {
            name: "テストユーザー",
            email: "short-password@example.com",
            password: "1234567",
            password_confirmation: "1234567"
          }
        }
      end.not_to change(User, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "129文字のパスワードでは登録されないこと" do
      long_password = "a" * 129

      expect do
        post user_registration_path, params: {
          user: {
            name: "テストユーザー",
            email: "long-password@example.com",
            password: long_password,
            password_confirmation: long_password
          }
        }
      end.not_to change(User, :count)

      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "ちょうど8文字のパスワードで登録できること" do
      expect do
        post user_registration_path, params: {
          user: {
            name: "テストユーザー",
            email: "eight-password@example.com",
            password: "12345678",
            password_confirmation: "12345678"
          }
        }
      end.to change(User, :count).by(1)

      expect(User.last.encrypted_password).to be_present
      expect(User.last.valid_password?("12345678")).to be(true)
    end

    it "ちょうど128文字のパスワードで登録できること" do
      password = "a" * 128

      expect do
        post user_registration_path, params: {
          user: {
            name: "テストユーザー",
            email: "128-password@example.com",
            password: password,
            password_confirmation: password
          }
        }
      end.to change(User, :count).by(1)

      user = User.last

      expect(user.encrypted_password).to be_present
      expect(user.valid_password?(password)).to be(true)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end
  end
end
