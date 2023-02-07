require 'test_helper'

class Api::Private::EmailWebhooksControllerTest < ActionController::TestCase
  test "valid email reply" do
    dave = users(:dave)
    p = posts(:zach_post_1)

    binding.pry

    assert_difference('Post.count', +1) do
      post :reply, params: mailgun_origin_params.merge({
        "In-Reply-To" => p.message_id,
        "sender" => dave.email,
        "stripped-text" => "This is my reply"
      })
      assert_response :success
    end
  end

  test "email reply not from mailgun origin" do
    dave = users(:dave)
    p = posts(:zach_post_1)

    post :reply, params: {
      "In-Reply-To" => p.message_id,
      "sender" => dave.email,
      "stripped-text" => "This is my reply"
    }
    assert_response :not_found
  end

  test "email opened updates visited status" do
    dave = users(:dave)
    p = posts(:zach_post_1)

    visited_status = VisitedStatus.where(user: dave, thread: p.thread).first_or_create

    visited_status.update(last_post_number_read: 0)

    post :opened, params: mailgun_origin_params.merge({
      "message-id" => p.message_id,
      "recipient" => dave.email,
    })
    assert_response :success

    visited_status.reload

    assert_equal visited_status.last_post_number_read, p.post_number
  end

  test "email opened doesn't update visited status if the thread has been visited since the post was made" do
    dave = users(:dave)
    p = posts(:zach_post_1)

    visited_status = VisitedStatus.where(user: dave, thread: p.thread).first_or_create

    visited_status.update(last_post_number_read: posts(:zach_post_1).post_number + 1)

    post :opened, params: mailgun_origin_params.merge({
      "message-id" => p.message_id,
      "recipient" => dave.email,
    })
    assert_response 200

    visited_status.reload

    assert_equal posts(:zach_post_1).post_number + 1, visited_status.last_post_number_read
  end

  test "email opened doesn't update visited status if the thread has been destroyed" do
    dave = users(:dave)
    p = posts(:zach_post_1)

    visited_status = VisitedStatus.where(user: dave, thread: p.thread).first_or_create

    posts(:zach_post_1).thread.destroy

    post :opened, params: mailgun_origin_params.merge({
      "message-id" => p.message_id,
      "recipient" => dave.email,
    })
    assert_response 406
  end

private
  def mailgun_origin_params
    api_key = ENV["MAILGUN_API_KEY"]
    digest = OpenSSL::Digest::SHA256.new
    timestamp = "123"
    token = "abc"
    signature = OpenSSL::HMAC.hexdigest(digest, api_key, "#{timestamp}#{token}")

    {timestamp: timestamp, token: token, signature: signature}
  end
end
