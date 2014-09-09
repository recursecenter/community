class CreateWelcomeMessages < ActiveRecord::Migration
  def change
    create_table :welcome_messages do |t|
      t.text :message
      t.timestamps
    end

    add_column :users, :last_read_welcome_message_at, :datetime
  end
end
