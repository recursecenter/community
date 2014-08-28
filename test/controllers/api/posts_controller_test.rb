class Api::PostsControllerTest < ActionController::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  test "users subscribed to a post's thread should get an email when a new post is made" do
    t = discussion_threads(:created_by_full_hacker_schooler)
    full_hacker_schooler = users(:full_hacker_schooler)
    full_hacker_schooler.subscribe_to(t, "")

    login(:dave)

    post :create, format: :json, thread_id: t.id, post: {body: "A new post"}, broadcast_to: [Group::Subscribers::ID]

    assert_equal 1, ActionMailer::Base.deliveries.size

    mail = ActionMailer::Base.deliveries.first

    assert_equal [full_hacker_schooler.email], mail.to
    assert_operator mail.text_part.body.to_s, :=~, /subscribed/
  end

  test "users subscribed and then unsubscribed from a post's thread shouldn't get an email when a new post is made" do
    t = discussion_threads(:created_by_full_hacker_schooler)
    full_hacker_schooler = users(:full_hacker_schooler)
    full_hacker_schooler.subscribe_to(t, "")

    Subscription.where(subscribable: t, user: full_hacker_schooler).first.update(subscribed: false)

    login(:dave)

    post :create, format: :json, thread_id: t.id, post: {body: "A new post"}

    assert_not ActionMailer::Base.deliveries.any? do |delivery|
      delivery.to.contains? full_hacker_schooler.email
    end
  end
end
