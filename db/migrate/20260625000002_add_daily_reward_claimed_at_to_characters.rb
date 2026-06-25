class AddDailyRewardClaimedAtToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :daily_reward_claimed_at, :datetime
    add_index :characters, :daily_reward_claimed_at
  end
end
