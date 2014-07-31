require 'test_helper'

class ReplyInfoVerifierTest < ActiveSupport::TestCase
  test "verify reply info" do
    user = users(:dave)
    thread = discussion_threads(:one)

    info = ReplyInfoVerifier.generate(user, thread)

    assert_kind_of String, info
    assert_equal [user, thread], ReplyInfoVerifier.verify(info)
  end
end
