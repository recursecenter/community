class Api::ThreadsControllerTest < ActionController::TestCase
  def setup
    $redis = MockRedis.new
  end

  test "User#subscribe_new_thread_in_subscribed_subforum is true and a new thread is made" do
    subforum = subforums(:programming)

    zach = users(:zach)
    zach.update(subscribe_new_thread_in_subscribed_subforum: true)
    zach.subscribe_to(subforum, "")

    login(:dave)

    assert_difference('DiscussionThread.count', +1) do
      post :create, format: :json, subforum_id: subforum.id,
        thread: {title: "A new thread"},
        post: {body: "A new post"}
    end

    assert Subscription.where(user: zach, subscribable: DiscussionThread.last).first.subscribed
  end

  test "User#subscribe_new_thread_in_subscribed_subforum is true and a new thread is made, but the user has unsubscribed from the subforum" do
    subforum = subforums(:programming)

    zach = users(:zach)
    zach.update(subscribe_new_thread_in_subscribed_subforum: true)
    zach.subscribe_to(subforum, "")
    Subscription.where(user: zach, subscribable: subforum).first.update(subscribed: false)

    login(:dave)

    assert_difference('DiscussionThread.count', +1) do
      post :create, format: :json, subforum_id: subforum.id,
        thread: {title: "A new thread"},
        post: {body: "A new post"}
    end

    assert_not DiscussionThread.last.subscription_for(zach).subscribed
  end
end
