class User < ActiveRecord::Base
  def self.create_or_update(user_data:, batch_data:)
    user = where(hacker_school_id: user_data["id"]).first_or_create({
      hacker_school_id: user_data["id"],
      first_name: user_data["first_name"],
      last_name: user_data["last_name"],
      email: user_data["email"],
      avatar_url: user_data["image"],
      batch_name: batch_data["name"]
    })
  end
end
