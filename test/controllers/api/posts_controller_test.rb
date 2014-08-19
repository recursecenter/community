class Api::PostsControllerTest < ActionController::TestCase
  def setup
    $redis = MockRedis.new
  end

  test "users subscribed to a post's thread should get an email when a new post is made" do
    t = discussion_threads(:one)
    zach = users(:zach)

    zach.subscribe_to(t, "testing")

    login(:dave)

    assert_difference('Delayed::Job.count', +1) do
      post :create, format: :json, thread_id: t.id, post: {body: "A new post"}
    end

    method, recipient_vars, users, post = YAML.load(Delayed::Job.last.handler).args

    assert_equal method, :new_post_in_subscribed_thread_email
    assert_equal users, [zach]
  end

  test "users subscribed and then unsubscribed from a post's thread shouldn't get an email when a new post is made" do
    t = discussion_threads(:one)
    zach = users(:zach)

    zach.subscribe_to(t, "testing")
    Subscription.where(subscribable: t, user: zach).first.update(subscribed: false)

    login(:dave)

    assert_difference('Delayed::Job.count', 0) do
      post :create, format: :json, thread_id: t.id, post: {body: "A new post"}
    end
  end
end
