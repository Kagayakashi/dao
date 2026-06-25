class AddSparringPointsToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :sparring_points, :integer, null: false, default: 3
    add_column :characters, :sparring_recovered_at, :datetime

    reversible do |direction|
      direction.up do
        Character.reset_column_information
        Character.update_all(sparring_recovered_at: Time.current)
      end
    end

    change_column_null :characters, :sparring_recovered_at, false
    change_column_default :characters, :sparring_recovered_at, from: nil, to: -> { "CURRENT_TIMESTAMP" }
  end
end
