require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "有効な属性であれば有効であること" do
      user = User.new(
        name: "テストユーザー",
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      expect(user).to be_valid
    end

    it "FactoryBotで有効なユーザーを生成できること" do
      user = build(:user)

      expect(user).to be_valid
    end

    it "名前が空の場合は無効であること" do
      user = build(:user, name: nil)

      expect(user).not_to be_valid
      expect(user.errors[:name]).to be_present
    end

    it "名前が50文字を超える場合は無効であること" do
      user = build(:user, name: "あ" * 51)

      expect(user).not_to be_valid
      expect(user.errors[:name]).to be_present
    end

    it "メールアドレスの前後の空白を除去し小文字に統一すること" do
      user = build(:user, email: " TEST@EXAMPLE.COM ")

      user.valid?

      expect(user.email).to eq("test@example.com")
    end

    it "同じメールアドレスでは登録できないこと" do
      existing_user = create(:user)
      duplicate_user = build(:user, email: existing_user.email.upcase)

      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to be_present
    end

    it "パスワード確認が空の場合は無効であること" do
      user = build(:user, password_confirmation: nil)

      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to be_present
    end

    it "パスワードとパスワード確認が一致しない場合は無効であること" do
      user = build(:user, password_confirmation: "different_password")

      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to be_present
    end
  end

  describe "confirmation instructions" do
    it "ユーザー登録時に確認メールの送信日時が保存されること" do
      user = create(:user, confirmed_at: nil)

      expect(user.confirmation_instructions_sent_at).to be_present
    end

    it "確認メールの再送時に送信日時が更新されること" do
      user = create(:user, confirmed_at: nil)
      user.update!(confirmation_instructions_sent_at: 1.hour.ago)

      user.resend_confirmation_instructions

      expect(user.reload.confirmation_instructions_sent_at)
        .to be_within(1.second).of(Time.current)
    end
  end
end
