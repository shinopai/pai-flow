# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invitations::CancelService, type: :service do
  describe ".call" do
    let!(:invitation) { create(:invitation) }

    context "pendingの場合" do
      it "招待を取り消し、responded_atを記録する" do
        expect do
          described_class.call(invitation: invitation)
        end.to change { invitation.reload.status }
          .from("pending").to("cancelled")

        expect(invitation.reload.responded_at).to be_present
      end

      it "招待レコードを削除せずに保持する" do
        expect do
          described_class.call(invitation: invitation)
        end.not_to change(Invitation, :count)
      end
    end

    context "pending以外の場合" do
      %w[accepted declined cancelled].each do |status|
        it "#{status}の招待は取り消せない" do
          invitation.update!(
            status: status,
            responded_at: Time.current
          )

          expect do
            described_class.call(invitation: invitation)
          end.to raise_error(ActiveRecord::RecordInvalid)

          expect(invitation.reload.status).to eq(status)
        end
      end
    end
  end
end
