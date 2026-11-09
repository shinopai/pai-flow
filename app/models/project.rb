class Project < ApplicationRecord
  belongs_to :team
  belongs_to :created_by, class_name: "User"
  belongs_to :assignee_membership,
             class_name: "TeamMembership",
             optional: true

  has_many :tasks, dependent: :delete_all
end
