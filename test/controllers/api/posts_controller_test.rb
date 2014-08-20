class Api::PostsControllerTest < ActionController::TestCase
  def setup
    $redis = MockRedis.new
  end

  test "users subscribed to a post's thread should get an email when a new post is made" do
    t = discussion_threads(:one)
    zach = users(:zach)

    zach.subscribe_to(t, "testing")

    login(:dave)

    post :create, format: :json, thread_id: t.id, post: {body: "A new post"}

    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.first

    assert_equal [zach.email], mail.to
    assert_operator mail.text_part.body.to_s, :=~, /subscribed/
  end

  test "users subscribed and then unsubscribed from a post's thread shouldn't get an email when a new post is made" do
    t = discussion_threads(:one)
    zach = users(:zach)

    zach.subscribe_to(t, "testing")
    Subscription.where(subscribable: t, user: zach).first.update(subscribed: false)

    login(:dave)

    post :create, format: :json, thread_id: t.id, post: {body: "A new post"}

    assert_equal [], ActionMailer::Base.deliveries
  end
end
