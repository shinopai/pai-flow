# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvitationPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:invitation) { create(:invitation, invitee: user, email: user.email) }
  let(:policy) { described_class.new(user, invitation) }

  describe "#show?" do
    context "招待された本人の場合" do
      it "許可する" do
        expect(policy.show?).to be true
      end
    end

    context "別のユーザーの場合" do
      it "拒否する" do
        another_user = create(:user)
        another_policy = described_class.new(another_user, invitation)

        expect(another_policy.show?).to be false
      end
    end

    context "登録メールアドレスが一致しない場合" do
      let(:invitation) do
        create(:invitation, email: "different@example.com")
      end

      it "拒否する" do
        expect(policy.show?).to be false
      end
    end
  end

  describe "#accept?" do
    it "招待された本人に許可する" do
      expect(policy.accept?).to be true
    end

    it "別のユーザーには拒否する" do
      another_user = create(:user)
      another_policy = described_class.new(another_user, invitation)

      expect(another_policy.accept?).to be false
    end
  end

  describe "#decline?" do
    it "招待された本人に許可する" do
      expect(policy.decline?).to be true
    end

    it "別のユーザーには拒否する" do
      another_user = create(:user)
      another_policy = described_class.new(another_user, invitation)

      expect(another_policy.decline?).to be false
    end
  end

  describe "Scope" do
    let!(:own_invitation) do
      create(:invitation, invitee: user, email: user.email)
    end
    let!(:another_invitation) { create(:invitation) }

    it "本人宛ての招待だけを取得する" do
      result = described_class::Scope.new(user, Invitation.all).resolve

      expect(result).to contain_exactly(own_invitation)
    end
  end
end
