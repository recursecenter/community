require 'test_helper'

class Api::ThreadsControllerTest < ActionController::TestCase
  test "User#subscribe_new_thread_in_subscribed_subforum is true and a new thread is made" do
    subforum = subforums(:programming)
    users(:full_hacker_schooler).subscribe_to(subforum, "")

    login(:dave)

    assert_difference('DiscussionThread.count', +1) do
      post :create, format: :json, params: {
        subforum_id: subforum.id,
        thread: {title: "A new thread"},
        post: {body: "A new post"},
        broadcast_to: [Group::Subscribers::ID]
      }
    end

    assert Subscription.where(user: users(:full_hacker_schooler),
                              subscribable: DiscussionThread.last).first.subscribed
  end

  test "User#subscribe_new_thread_in_subscribed_subforum is true and a new thread is made, but the user has unsubscribed from the subforum" do
    subforum = subforums(:programming)
    user = users(:full_hacker_schooler)
    user.subscribe_to(subforum, "")
    Subscription.where(user: user, subscribable: subforum).first.update(subscribed: false)

    login(:dave)

    assert_difference('DiscussionThread.count', +1) do
      post :create, format: :json, params: {
        subforum_id: subforum.id,
        thread: {title: "A new thread"},
        post: {body: "A new post"}
      }
    end

    assert_not DiscussionThread.last.subscription_for(user).subscribed
  end
end
