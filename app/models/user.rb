class User < ActiveRecord::Base
  has_many :threads, foreign_key: 'created_by_id', class_name: 'DiscussionThread'
  has_many :posts, foreign_key: 'author_id'
  has_many :notifications
  has_many :mentions, class_name: 'Notifications::Mention'
  has_many :group_memberships
  has_many :groups, through: :group_memberships
  has_many :subscriptions
  has_and_belongs_to_many :roles

  scope :ordered_by_first_name, -> { order(first_name: :asc) }

  def self.create_or_update_from_api_data(user_data)
    user = where(hacker_school_id: user_data["id"]).first_or_initialize

    user.hacker_school_id = user_data["id"]
    user.first_name = user_data["first_name"]
    user.last_name = user_data["last_name"]
    user.email = user_data["email"]
    user.avatar_url = user_data["image"]
    user.batch_name = user_data["batch"]["name"]
    user.groups = [Group.everyone, Group.for_batch_api_data(user_data["batch"])]

    if user_data["currently_at_hacker_school"]
      user.groups += [Group.current_hacker_schoolers]
    end

    if user_data["is_faculty"]
      user.groups += [Group.faculty]
    end

    user.save!

    user
  end

  def name
    "#{first_name} #{last_name}"
  end

  def mention_for_post(post)
    mentions.where(post: post, mentioned_by: post.author).first_or_create
  end

  def subscribe_to(subscribable, reason)
    subscription = subscribable.subscription_for(self)
    subscription.subscribed = true
    subscription.reason = reason
    subscription.save!
  end

  def has_role?(role_name)
    roles.where(name: role_name).present?
  end

  def has_roles?(*role_names)
    roles.where(name: role_names).count == role_names.count
  end
end
