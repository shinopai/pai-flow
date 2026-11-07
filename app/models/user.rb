class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :confirmable, :lockable, :validatable

  before_validation :normalize_email

  validates :name, presence: true, length: { maximum: 50 }
  validates :password_confirmation, presence: true, on: :create

  private

  def normalize_email
    self.email = email.strip.downcase if email.present?
  end
end
