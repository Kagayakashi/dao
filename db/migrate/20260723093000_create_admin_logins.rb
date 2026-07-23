class CreateAdminLogins < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_logins do |t|
      t.integer :game_user_id
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :admin_logins, :created_at
    add_index :admin_logins, :game_user_id
  end
end
