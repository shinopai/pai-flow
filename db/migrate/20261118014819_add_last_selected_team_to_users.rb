class AddLastSelectedTeamToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users,
                  :last_selected_team,
                  null: true,
                  foreign_key: { to_table: :teams }
  end
end
