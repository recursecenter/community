require 'test_helper'

class ReplyInfoVerifierTest < ActiveSupport::TestCase
  def setup
    @user = users(:dave)
    @post = posts(:zach_post_1)
    @info = ReplyInfoVerifier.generate(@user, @post)
  end

  test "generates a string" do
    assert_kind_of String, @info
  end

  test "v2: verify returns a pair of the user and post" do
    assert_equal [@user, @post], ReplyInfoVerifier.verify(@info)
  end

  test "v2: generated info is case-insensitive" do
    assert_nothing_raised ReplyInfoVerifier::InvalidSignature do
      assert_equal [@user, @post], ReplyInfoVerifier.verify(@info.downcase)
      assert_equal [@user, @post], ReplyInfoVerifier.verify(@info.upcase)
    end
  end

  test "tampering with info causes an error" do
    assert_raises(ReplyInfoVerifier::InvalidSignature) { ReplyInfoVerifier.verify(@info[1..-1]) }
    assert_raises(ReplyInfoVerifier::InvalidSignature) { ReplyInfoVerifier.verify(@info[0..-2]) }
  end

  test "v1 reply info" do
    user = users(:dave)
    thread = discussion_threads(:one)
    info = ReplyInfoVerifier.generate(user, thread)
    info.slice!("v2--")

    assert_equal [@user, thread.posts.by_number.last], ReplyInfoVerifier.verify(info)
  end
end
