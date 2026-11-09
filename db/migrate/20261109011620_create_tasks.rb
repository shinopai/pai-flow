class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :project, null: false,
                             foreign_key: { on_delete: :cascade },
                             index: false

      t.references :parent_task, null: true,
                                 foreign_key: { to_table: :tasks, on_delete: :cascade },
                                 index: false

      t.references :created_by, null: false,
                                foreign_key: { to_table: :users, on_delete: :restrict },
                                index: false

      t.references :assignee_membership, null: true,
                                         foreign_key: { to_table: :team_memberships, on_delete: :restrict },
                                         index: false

      t.string :title, null: false
      t.text :description
      t.date :due_date
      t.string :priority, null: false
      t.string :status, null: false
      t.integer :position, null: false

      t.timestamps null: false

      t.index :project_id
      t.index :parent_task_id
      t.index :assignee_membership_id
      t.index :due_date

      t.index [:project_id, :status]
      t.index [:project_id, :priority]
      t.index [:project_id, :due_date]
      t.index [:project_id, :position]
      t.index [:parent_task_id, :position]
      t.index [:assignee_membership_id, :due_date]
      t.index [:project_id, :created_at]
    end
  end
end
