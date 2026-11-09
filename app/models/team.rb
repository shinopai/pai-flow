class Team < ApplicationRecord
  has_many :team_memberships, dependent: :restrict_with_exception
  has_many :invitations, dependent: :restrict_with_exception
  has_many :projects, dependent: :restrict_with_exception
end
