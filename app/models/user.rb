class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :confirmable, :lockable, :validatable

  has_many :team_memberships, dependent: :restrict_with_exception

  has_many :received_invitations,
           class_name: "Invitation",
           foreign_key: :invitee_id,
           inverse_of: :invitee,
           dependent: :restrict_with_exception

  has_many :sent_invitations,
           class_name: "Invitation",
           foreign_key: :invited_by_id,
           inverse_of: :invited_by,
           dependent: :restrict_with_exception

  has_many :created_projects,
           class_name: "Project",
           foreign_key: :created_by_id,
           inverse_of: :created_by,
           dependent: :restrict_with_exception

  has_many :created_tasks,
           class_name: "Task",
           foreign_key: :created_by_id,
           inverse_of: :created_by,
           dependent: :restrict_with_exception

  before_validation :normalize_email

  validates :name, presence: true, length: { maximum: 50 }
  validates :password_confirmation, presence: true, on: :create

  def send_devise_notification(notification, *args)
    result = super

    update!(confirmation_instructions_sent_at: Time.current) if notification == :confirmation_instructions && persisted?

    result
  end

  private

  def normalize_email
    self.email = email.strip.downcase if email.present?
  end
end
