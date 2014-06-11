class User < ActiveRecord::Base
  has_many :threads, foreign_key: 'created_by_id', class_name: 'DiscussionThread'
  has_many :posts, foreign_key: 'author_id'
  has_many :notifications

  def name
    "#{first_name} #{last_name}"
  end

  def self.create_or_update_from_api_data(user_data)
    user = where(hacker_school_id: user_data["id"]).first_or_initialize

    user.hacker_school_id = user_data["id"]
    user.first_name = user_data["first_name"]
    user.last_name = user_data["last_name"]
    user.email = user_data["email"]
    user.avatar_url = user_data["image"]
    user.batch_name = user_data["batch"]["name"]

    user.save!

    user
  end
end
