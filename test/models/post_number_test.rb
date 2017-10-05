require 'test_helper'

class PostNumberTest < ActiveSupport::TestCase
  # This test is multi-threaded and thus (we think) can't use
  # transactional fixtures.
  self.use_transactional_tests = false

  test "posts created concurrently have monotonically increasing post numbers" do
    zach = users(:zach)

    t = subforums(:programming).threads.create!(
      created_by: zach,
      last_post_created_by: zach,
      title: "A new thread")

    20.times.map do |i|
      Thread.new do
        sleep 0.001
        Post.create!(thread: t, body: "a randomly ordered post #{i}", author: zach)
        ActiveRecord::Base.clear_active_connections!
      end
    end.each(&:join)

    assert_equal 20, t.highest_post_number
    assert_equal (1..20).to_a, t.posts.order(post_number: :asc).map(&:post_number)
  end
end
