require 'digest'
require 'set'

class User < ActiveRecord::Base
  include Searchable
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
    user.avatar_url = user_data["image"] if user_data["has_photo"]
    user.batch_name = user_data["batch"]["name"]
    user.groups = [Group.everyone, Group.for_batch_api_data(user_data["batch"])]

    if user_data["currently_at_hacker_school"]
      user.groups += [Group.current_hacker_schoolers]

      subforums = ["New York", "455 Broadway"].map { |name| Subforum.where(name: name).first! }
      subforums.each do |subforum|
        user.subscribe_to_unless_existing(subforum, "You are receiving emails because you were auto-subscribed at the beginning of your batch.")
      end
    end

    if user_data["is_faculty"]
      user.groups += [Group.faculty]
    end

    roles = user.roles.to_set

    roles << Role.everyone

    if (Date.parse(user_data["batch"]["start_date"]) - 1.day).past?
      roles << Role.full_hacker_schooler
    end

    if user_data["is_faculty"]
      roles |= [Role.everyone, Role.full_hacker_schooler, Role.admin]
    end

    user.roles = roles.to_a

    user.save!

    user
  end

  def name
    "#{first_name} #{last_name}"
  end

  def avatar_url
    super || gravatar_url
  end

  def gravatar_url
    default_url = "https://gravatar.com/avatar/images/guest.png"
    gravatar_id = Digest::MD5.hexdigest(email.downcase)
    "https://gravatar.com/avatar/#{gravatar_id}.png?s=150&d=#{CGI.escape(default_url)}"
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

  def subscribe_to_unless_existing(subscribable, reason)
    subscription = subscribable.subscription_for(self)

    if subscription.new_record?
      subscription.update!(subscribed: true, reason: reason)
    end
  end

  def satisfies_roles?(*roles)
    self.roles.where(id: roles).count == roles.uniq.count
  end

  def last_read_welcome_message_at
    super || Time.zone.at(0).to_datetime # Unix Epoch start
  end

  def to_search_mapping
    user_data = Hash.new
    user_data["suggest"] = {
      input: [name, email, first_name, last_name],
      output: name,
      payload: {id: id, email: email, first_name: first_name, last_name: last_name, name: name}
    }

    { index: { _id: id, data: user_data } }
  end
end
