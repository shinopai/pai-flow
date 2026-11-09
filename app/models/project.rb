class Project < ApplicationRecord
  belongs_to :team
  belongs_to :created_by, class_name: "User"
  belongs_to :assignee_membership,
             class_name: "TeamMembership",
             optional: true

  has_many :tasks, dependent: :delete_all

  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  validate :due_date_must_be_valid

  validates :status,
            presence: true,
            inclusion: { in: %w[順調 リスクあり 要対応 保留中 完了] }

  private

  def due_date_must_be_valid
    return if due_date_before_type_cast.blank?

    return unless due_date.nil?

    errors.add(:due_date, "は正しい日付を入力してください")
  end
end
