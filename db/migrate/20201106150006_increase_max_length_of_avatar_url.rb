class IncreaseMaxLengthOfAvatarUrl < ActiveRecord::Migration[5.2]
  def change
    change_column :users, :avatar_url, :string, :limit => nil
  end
end
