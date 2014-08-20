class Api::ThreadsController < Api::ApiController
  load_and_authorize_resource :thread, class: 'DiscussionThread'

  include MentionedUsers
  include SubscriptionActions

  has_subscribable :thread

  def show
    @thread.mark_as_visited_for(current_user, @thread.posts.last)
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

    subscribe_subforum_subscribers_to_new_thread
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

  def subscribe_subforum_subscribers_to_new_thread
    to_be_subscribed = User.joins(:subscriptions).
      where.not(id: current_user).
      where(subscribe_new_thread_in_subscribed_subforum: true, subscriptions: {subscribable: @thread.subforum, subscribed: true})

    to_be_subscribed.each do |user|
      user.subscribe_to(@thread, "You are receiving emails because you were subscribed to this thread's subforum.")
    end
  end
end
