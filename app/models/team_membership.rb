class TeamMembership < ApplicationRecord
  belongs_to :team
  belongs_to :user

  has_many :assigned_projects,
           class_name: "Project",
           foreign_key: :assignee_membership_id,
           inverse_of: :assignee_membership,
           dependent: :restrict_with_exception

  has_many :assigned_tasks,
           class_name: "Task",
           foreign_key: :assignee_membership_id,
           inverse_of: :assignee_membership,
           dependent: :restrict_with_exception

  has_many :comments, dependent: :restrict_with_exception
end
