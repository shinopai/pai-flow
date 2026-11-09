class Comment < ApplicationRecord
  belongs_to :task
  belongs_to :team_membership
end
