class CreateTeamMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :team_memberships do |t|
      t.references :team, null: false, foreign_key: { on_delete: :restrict }, index: false
      t.references :user, null: false, foreign_key: { on_delete: :restrict }, index: false

      t.string :role, null: false
      t.string :status, null: false
      t.datetime :joined_at, null: false
      t.datetime :left_at

      t.timestamps null: false

      t.check_constraint "role IN ('owner', 'member', 'guest')",
                         name: "check_team_memberships_role"

      t.check_constraint "status IN ('active', 'left')",
                         name: "check_team_memberships_status"

      t.check_constraint(
        "(status = 'active' AND left_at IS NULL) OR " \
        "(status = 'left' AND left_at IS NOT NULL)",
        name: "check_team_memberships_status_left_at"
      )

      t.index %i[team_id user_id],
              unique: true,
              where: "status = 'active'"

      t.index :team_id,
              unique: true,
              where: "role = 'owner' AND status = 'active'"

      t.index :user_id
    end
  end
end
