class Api::Private::EmailWebhooksControllerTest < ActionController::TestCase
  def setup
    $redis = MockRedis.new
    @reply_info = ReplyInfoVerifier.generate(users(:dave), posts(:zach_post_1))
  end

  test "valid email reply" do
    assert_difference('Post.count', +1) do
      post :reply, mailgun_origin_params.merge({
        reply_info: @reply_info,
        "stripped-text" => "This is my reply"
      })
      assert_response :success
    end
  end

  test "email reply not from mailgun origin" do
    post :reply, reply_info: @reply_info, "stripped-text" => "This is my reply"
    assert_response :not_found
  end

  test "email reply with bad reply_info" do
    post :reply, mailgun_origin_params.merge({
      reply_info: @reply_info[0...-1],
      "stripped-text" => "This is my reply"
    })
    assert_response 406
  end

  test "email opened updates visited status" do
    visited_status = VisitedStatus.where(user: users(:dave), visitable: posts(:zach_post_1).thread).first_or_create

    visited_status.update(last_visited: 1.day.ago)
    posts(:zach_post_1).update(created_at: DateTime.current)

    post :opened, mailgun_origin_params.merge({reply_info: @reply_info})
    assert_response :success

    visited_status.reload

    assert_equal visited_status.last_visited.to_i, posts(:zach_post_1).created_at.to_i
  end

  test "email opened doesn't update visited status if the thread has been visited since the post was made" do
    visited_status = VisitedStatus.where(user: users(:dave), visitable: posts(:zach_post_1).thread).first_or_create

    visited_status.update(last_visited: DateTime.current)
    posts(:zach_post_1).update(created_at: 1.day.ago)

    post :opened, mailgun_origin_params.merge({reply_info: @reply_info})
    assert_response :success

    visited_status.reload

    assert_operator visited_status.last_visited, :>, posts(:zach_post_1).created_at
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
