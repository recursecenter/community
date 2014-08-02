require 'test_helper'

class ReplyInfoVerifierTest < ActiveSupport::TestCase
  def setup
    @user = users(:dave)
    @thread = discussion_threads(:one)
    @info = ReplyInfoVerifier.generate(@user, @thread)
  end

  test "generates a string" do
    assert_kind_of String, @info
  end

  test "verify returns a pair of the user and thread" do
    assert_equal [@user, @thread], ReplyInfoVerifier.verify(@info)
  end

  test "generated info is case-insensitive" do
    assert begin
      assert_equal [@user, @thread], ReplyInfoVerifier.verify(@info.downcase)
      assert_equal [@user, @thread], ReplyInfoVerifier.verify(@info.upcase)
    rescue ReplyInfoVerifier::InvalidSignature => e
      false
    end, "is not case-insensitive"
  end

  test "tampering with info causes an error" do
    assert_raises(ReplyInfoVerifier::InvalidSignature) { ReplyInfoVerifier.verify(@info[1..-1]) }
    assert_raises(ReplyInfoVerifier::InvalidSignature) { ReplyInfoVerifier.verify(@info[0..-2]) }
  end
end
