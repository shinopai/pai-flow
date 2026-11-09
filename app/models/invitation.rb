class Invitation < ApplicationRecord
  belongs_to :team
  belongs_to :invitee, class_name: "User"
  belongs_to :invited_by, class_name: "User"
end
