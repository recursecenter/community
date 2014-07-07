class Group < ActiveRecord::Base
  has_and_belongs_to_many :users

  def self.everyone
    where(name: "Everyone").first_or_create!
  end

  def self.for_batch_api_data(batch_data)
    where(hacker_school_batch_id: batch_data["id"],
          name: batch_data["name"]).first_or_create!
  end
end
