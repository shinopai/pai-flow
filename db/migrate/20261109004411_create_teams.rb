class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.string :name, null: false, limit: 100

      t.timestamps null: false
    end
  end
end
