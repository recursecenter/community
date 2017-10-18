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

      if @thread.created_by.subscribe_on_create
        @thread.created_by.subscribe_to(@thread, "You are receiving emails because you created this thread.")
      end

      if @post.broadcast_to_subscribers
        Subscription.bulk_insert(values: subscription_hashes)
      end
    end

    @autocomplete_users = User.select(:id, :first_name, :last_name).ordered_by_first_name
    @valid_broadcast_groups = valid_broadcast_groups

    Delayed::Job.enqueue NewThreadNotificationJob.new(@post, mentioned_user_ids)
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
      merge(created_by: current_user,
        last_post_created_by: current_user,
        subforum: subforum)
  end

  def valid_broadcast_groups
    Group.all + [Group::Subscribers.new("Thread Subscribers")]
  end

  def to_be_subscribed
    User.joins(:subscriptions).
      where.not(id: current_user.id).
      where(subscribe_new_thread_in_subscribed_subforum: true, subscriptions: {subscribable: @thread.subforum, subscribed: true})
  end

  def subscription_hashes
    to_be_subscribed.map do |user|
      {
        subscribed: true,
        user_id: user.id,
        subscribable_id: @thread.id,
        subscribable_type: @thread.class.name,
        reason: "You are receiving emails because you were subscribed to this thread's subforum."
      }
    end
  end
end
