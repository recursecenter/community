require 'digest'

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

  def display_email
    %{"#{name}" <#{email}>}
  end

  def mention_for_post(post)
    mentions.where(post: post, mentioned_by: post.author).first_or_create
  end

  def subscribed_to?(subscribable)
    subscriptions.where(subscribed: true, subscribable: subscribable).exists?
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

  def last_read_welcome_message_at
    super || Time.zone.at(0).to_datetime # Unix Epoch start
  end

  def is_admin?
    self.roles.include? Role.admin
  end

  def deactivate
    self.roles = []
    subscriptions.destroy_all
    update!(deactivated: true)
  end

  concerning :Searchable do
    def to_search_mapping
      user_data = {
        suggest: {
          input: prefix_phrases(name) + [email],
          output: name,
          payload: {id: id, email: email, first_name: first_name, last_name: last_name, name: name, required_role_ids: []}
        }
      }

      {index: {_id: id, data: user_data}}
    end
  end
end
