require 'set'

class MentionNotifier < Notifier
  attr_reader :post, :mentioned_users

  def initialize(post, mentioned_users)
    @post = post
    @mentioned_users = mentioned_users
  end

  def notify(email_recipients)
    possible_recipients.each do |user|
      mention = user.mentions.create(post: post, mentioned_by: post.author)
      PubSub.publish :created, :notification, mention
    end

    email_recipients.each do |user|
      NotificationMailer.delay.user_mentioned_email(mention)
    end
  end

  def should_email?(u)
    Ability.new(u).can?(:read, post) && u.email_on_mention?
  end

  def possible_recipients
    @possible_recipients ||= (
      mentioned_users.select { |u| Ability.new(u).can? :read, post } -
        post.mentions.map(&:user)
    ).to_set
  end
end
