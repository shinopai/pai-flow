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

  validates :role, presence: true, inclusion: { in: %w[owner member guest] }
  validates :status, presence: true, inclusion: { in: %w[active left] }
  validates :joined_at, presence: true
  validates :left_at, presence: true, if: -> { status == "left" }
  validates :left_at, absence: true, if: -> { status == "active" }
end
