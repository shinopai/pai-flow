class Task < ApplicationRecord
  belongs_to :project
  belongs_to :created_by, class_name: "User"

  belongs_to :assignee_membership,
             class_name: "TeamMembership",
             optional: true

  belongs_to :parent_task,
             class_name: "Task",
             optional: true

  has_many :subtasks,
           class_name: "Task",
           foreign_key: :parent_task_id,
           inverse_of: :parent_task,
           dependent: :delete_all

  has_many :comments, dependent: :delete_all
end
