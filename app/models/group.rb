class Group < ActiveRecord::Base
  has_many :group_memberships
  has_many :users, through: :group_memberships

  def self.everyone
    where(name: "Everyone").first_or_create!
  end

  def self.current_hacker_schoolers
    where(name: "Current Hacker Schoolers").first_or_create!
  end

  def self.faculty
    where(name: "Faculty").first_or_create!
  end

  def self.for_batch_api_data(batch_data)
    group = where(hacker_school_batch_id: batch_data["id"]).first_or_initialize
    group.name = batch_data["name"]
    group.save!
    group
  end
end
