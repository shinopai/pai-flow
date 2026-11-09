class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :task, null: false,
                          foreign_key: { on_delete: :cascade },
                          index: false

      t.references :team_membership, null: false,
                                     foreign_key: { on_delete: :restrict },
                                     index: false

      t.text :body, null: false

      t.timestamps null: false

      t.index :task_id
    end
  end
end
