class Invitation < ApplicationRecord
  belongs_to :team
  belongs_to :invitee, class_name: "User"
  belongs_to :invited_by, class_name: "User"

  validates :email,
            presence: true,
            format: { with: Devise.email_regexp },
            length: { maximum: 255 }

  validates :status,
            presence: true,
            inclusion: { in: %w[pending accepted declined cancelled] }

  validates :responded_at, absence: true, if: -> { status == "pending" }
  validates :responded_at, presence: true, unless: -> { status == "pending" }
end
