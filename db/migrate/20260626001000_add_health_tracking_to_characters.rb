class AddHealthTrackingToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :current_health, :integer
    add_column :characters, :health_recovered_at, :datetime
  end
end
