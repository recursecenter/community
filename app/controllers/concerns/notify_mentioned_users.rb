module NotifyMentionedUsers
  extend ActiveSupport::Concern

  def notify_newly_mentioned_users!(post)
    (mentioned_users - post.mentions.map(&:user)).each do |user|
      if Ability.new(user).can? :read, post
        mention = user.mentions.create(post: post, mentioned_by: post.author)
        PubSub.publish :created, :notification, mention

        if user.email_on_mention?
          NotificationMailer.delay.user_mentioned_email(mention)
        end
      end
    end
  end

private
  def mentioned_users
    if mention_params[:mentions].present?
      User.where(id: mention_params[:mentions])
    else
      []
    end
  end

  def mention_params
    params.permit(mentions: [])
  end
end
