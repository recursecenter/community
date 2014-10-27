require 'set'

class MentionNotifier < Notifier
  attr_reader :post, :mentioned_users

  def initialize(post, mentioned_users)
    @post = post
    @mentioned_users = mentioned_users
  end

  def notify(email_recipients=possible_recipients)
    email_recipients.each do |user|
      if user.subscribe_when_mentioned?
        user.subscribe_to(post.thread, "You are receiving emails because you were @mentioned in this thread.")
      end

      mention = user.mention_for_post(post)
      NotificationMailer.delay.user_mentioned_email(mention)
    end
  end

  def should_email?(u)
    Ability.new(u).can?(:read, post) && u.email_on_mention?
  end

  def possible_recipients
    @possible_recipients ||= (
      mentioned_users.select { |u| Ability.new(u).can? :read, post } -
        post.mentions.includes(:user).map(&:user)
    ).to_set
  end
end
