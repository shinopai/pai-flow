class CreateProjects < ActiveRecord::Migration[8.1]
  # rubocop: disable-next Metrics/AbcSize
  def change
    create_table :projects do |t|
      t.references :team, null: false,
                          foreign_key: { on_delete: :restrict },
                          index: false

      t.references :created_by, null: false,
                                foreign_key: { to_table: :users, on_delete: :restrict },
                                index: false

      t.references :assignee_membership, null: true,
                                         foreign_key: { to_table: :team_memberships, on_delete: :restrict },
                                         index: false

      t.string :name, null: false
      t.text :description
      t.date :due_date
      t.string :status, null: false
      t.datetime :archived_at

      t.timestamps null: false

      t.index :team_id
      t.index :assignee_membership_id

      t.index %i[team_id updated_at]
      t.index %i[team_id due_date]
      t.index %i[team_id name]
      t.index %i[team_id status]
      t.index %i[team_id assignee_membership_id]
    end
  end
end
