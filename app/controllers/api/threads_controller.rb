class Api::ThreadsController < Api::ApiController
  load_and_authorize_resource :thread, class: 'DiscussionThread'

  include MentionedUsers
  include SubscriptionActions

  has_subscribable :thread

  def show
    @thread.mark_visited(current_user)
    @autocomplete_users = User.select(:id, :first_name, :last_name).ordered_by_first_name
  end

  def create
    @thread.transaction do
      @thread.save!
      @post = @thread.posts.create!(post_params)
    end
    @autocomplete_users = User.select(:id, :first_name, :last_name).ordered_by_first_name

    NotificationCoordinator.new(
      MentionNotifier.new(@post, mentioned_users),
      SubforumSubscriptionNotifier.new(@post.thread),
      BroadcastNotifier.new(@post)
    ).notify

    if @thread.created_by.subscribe_on_create
      @thread.created_by.subscribe_to(@thread, "You are receiving emails because you created this thread.")
    end
  end

private
  def create_params
    subforum = Subforum.find(params[:subforum_id])
    params.require(:thread).permit(:title).
      merge(created_by: current_user, subforum: subforum)
  end

  def post_params
    params.require(:post).permit(:body).
      merge(author: current_user,
            broadcast_groups: Group.where(id: params.permit(broadcast_to: [])[:broadcast_to]))
  end
end
