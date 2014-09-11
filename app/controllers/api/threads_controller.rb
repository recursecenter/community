class Api::ThreadsController < Api::ApiController
  load_and_authorize_resource :thread, class: 'DiscussionThread'

  include MentionedUsers
  include SubscriptionActions
  include PostParams

  has_subscribable :thread

  def show
    @thread.mark_as_visited(current_user)
    @autocomplete_users = User.select(:id, :first_name, :last_name).ordered_by_first_name
    @valid_broadcast_groups = valid_broadcast_groups
  end

  def create
    @thread.transaction do
      @thread.save!
      @post = @thread.posts.create!(post_params)
    end
    @autocomplete_users = User.select(:id, :first_name, :last_name).ordered_by_first_name
    @valid_broadcast_groups = valid_broadcast_groups

    NotificationCoordinator.new(
      MentionNotifier.new(@post, mentioned_users),
      SubforumSubscriptionNotifier.new(@post.thread),
      BroadcastNotifier.new(@post)
    ).notify

    if @thread.created_by.subscribe_on_create
      @thread.created_by.subscribe_to(@thread, "You are receiving emails because you created this thread.")
    end

    if @post.broadcast_to_subscribers
      subscribe_subforum_subscribers_to_new_thread
    end
  end

  def pin
    @thread.update(pinned: true)
    render 200, json: {}
  end

  def unpin
    @thread.update(pinned: false)
    render 200, json: {}
  end

private
  def create_params
    subforum = Subforum.find(params[:subforum_id])
    params.require(:thread).permit(:title).
      merge(created_by: current_user, subforum: subforum)
  end

  def subscribe_subforum_subscribers_to_new_thread
    to_be_subscribed = User.joins(:subscriptions).
      where.not(id: current_user).
      where(subscribe_new_thread_in_subscribed_subforum: true, subscriptions: {subscribable: @thread.subforum, subscribed: true})

    to_be_subscribed.each do |user|
      user.subscribe_to(@thread, "You are receiving emails because you were subscribed to this thread's subforum.")
    end
  end

  def valid_broadcast_groups
    Group.all + [Group::Subscribers.new("Thread Subscribers")]
  end
end
