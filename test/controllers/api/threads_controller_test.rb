class Api::ThreadsControllerTest < ActionController::TestCase
  def setup
    $redis = MockRedis.new
  end

  test "User#subscribe_new_thread_in_subscribed_subforum is true and a new thread is made" do
    subforum = subforums(:programming)

    login(:dave)

    assert_difference('DiscussionThread.count', +1) do
      post :create, format: :json, subforum_id: subforum.id,
        thread: {title: "A new thread"},
        post: {body: "A new post"}
    end

    assert Subscription.where(user: users(:subscribes_to_new_threads),
                              subscribable: DiscussionThread.last).first.subscribed
  end

  test "User#subscribe_new_thread_in_subscribed_subforum is true and a new thread is made, but the user has unsubscribed from the subforum" do
    subforum = subforums(:programming)
    user = users(:subscribes_to_new_threads)
    Subscription.where(user: user, subscribable: subforum).first.update(subscribed: false)

    login(:dave)

    assert_difference('DiscussionThread.count', +1) do
      post :create, format: :json, subforum_id: subforum.id,
        thread: {title: "A new thread"},
        post: {body: "A new post"}
    end

    assert_not DiscussionThread.last.subscription_for(user).subscribed
  end
end
