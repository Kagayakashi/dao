class AddSectToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :sect_key, :string
    add_column :characters, :sect_rank, :integer, null: false, default: 0
    add_column :characters, :sect_contribution, :bigint, null: false, default: 0
    add_column :characters, :sect_task_completed_at, :datetime

    add_index :characters, :sect_key
    add_index :characters, :sect_contribution
  end
end
