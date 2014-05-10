class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :avatar_url
      t.string :batch_name
      t.integer :hacker_school_id

      t.timestamps
    end

    add_index :users, :hacker_school_id
  end
end
