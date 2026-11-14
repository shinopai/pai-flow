class AddConfirmationInstructionsSentAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmation_instructions_sent_at, :datetime
  end
end
