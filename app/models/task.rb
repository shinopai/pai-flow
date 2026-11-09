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

  validates :title, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  validate :due_date_must_be_valid

  validates :priority,
            presence: true,
            inclusion: { in: %w[high medium low] }

  validates :status,
            presence: true,
            inclusion: { in: %w[not_started in_progress completed] }

  validates :position,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  private

  def due_date_must_be_valid
    return if due_date_before_type_cast.blank?

    return unless due_date.nil?

    errors.add(:due_date, "は正しい日付を入力してください")
  end
end
