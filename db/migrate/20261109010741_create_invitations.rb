class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :team, null: false,
                          foreign_key: { on_delete: :restrict },
                          index: false

      t.references :invitee, null: false,
                             foreign_key: { to_table: :users, on_delete: :restrict },
                             index: false

      t.references :invited_by, null: false,
                                foreign_key: { to_table: :users, on_delete: :restrict },
                                index: false

      t.string :email, null: false
      t.string :status, null: false
      t.datetime :responded_at

      t.timestamps null: false

      t.check_constraint(
        "status IN ('pending', 'accepted', 'declined', 'cancelled')",
        name: "check_invitations_status"
      )

      t.index %i[team_id invitee_id],
              unique: true,
              where: "status = 'pending'"

      t.index :invitee_id
      t.index :team_id
    end
  end
end
