class Comment < ApplicationRecord
  belongs_to :task
  belongs_to :team_membership

  validates :body, presence: true, length: { maximum: 1000 }
end
