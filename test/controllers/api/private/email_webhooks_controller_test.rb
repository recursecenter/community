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
