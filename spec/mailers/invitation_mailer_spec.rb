require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "#invite" do
    let(:invitation) { create(:invitation) }

    subject(:mail) { described_class.invite(invitation) }

    it "招待先のメールアドレスを宛先に設定する" do
      expect(mail.to).to eq([invitation.email])
    end

    it "チーム名を含む件名を設定する" do
      expect(mail.subject).to eq("#{invitation.team.name}への招待")
    end

    it "HTML形式の本文に招待情報と招待詳細URLを含める" do
      body = mail.html_part.body.decoded

      expect(body).to include(invitation.invited_by.name)
      expect(body).to include(invitation.team.name)
      expect(body).to include("/invitations/#{invitation.id}")
    end

    it "テキスト形式の本文に招待情報と招待詳細URLを含める" do
      body = mail.text_part.body.decoded

      expect(body).to include(invitation.invited_by.name)
      expect(body).to include(invitation.team.name)
      expect(body).to include("/invitations/#{invitation.id}")
    end
  end
end
