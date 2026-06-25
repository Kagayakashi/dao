class AddDonationCurrencyToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :donation_currency, :bigint, null: false, default: 0
  end
end
