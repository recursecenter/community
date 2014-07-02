module NotifyOfMentions
  extend ActiveSupport::Concern

  def notify_mentioned_users!(post)
    mentioned_users.each do |user|
      if Ability.new(user).can? :read, post
        mention = user.mentions.create(post: post, mentioned_by: post.author)
        PubSub.publish :created, :notification, mention
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
