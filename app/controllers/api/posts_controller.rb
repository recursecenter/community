class Api::PostsController < Api::ApiController
  load_and_authorize_resource :post

  def create
    @post.save!
    @post.thread.mark_as_visited_for(current_user)
    PubSub.publish :created, :post, @post

    notify_mentioned_users!
  end

  def update
    @post.update!(update_params)
    PubSub.publish :updated, :post, @post
  end

private

  def notify_mentioned_users!
    mentioned_users.each do |user|
      if Ability.new(user).can? :read, @post
        user.mentions.create(post: @post, mentioned_by: @post.author)
      end
    end
  end

  def mentioned_users
    if params[:mentions].present?
      User.where(id: params[:mentions])
    else
      []
    end
  end

  def create_params
    thread = DiscussionThread.find(params[:thread_id])
    post_params.merge(thread: thread, author: current_user)
  end

  def update_params
    post_params
  end

  def post_params
    params.require(:post).permit(:body)
  end
end
