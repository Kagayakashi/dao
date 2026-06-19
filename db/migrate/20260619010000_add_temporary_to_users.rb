class AddTemporaryToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :temporary, :boolean, null: false, default: false
  end
end
