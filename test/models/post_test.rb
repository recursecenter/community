require 'test_helper'

class PostTest < ActiveSupport::TestCase
  test "Users can only edit posts they wrote" do
    posts(:zach_post_1).thread.subforum.required_role_ids = []
    posts(:dave_post_1).thread.subforum.required_role_ids = []

    ability = Ability.new(users(:zach))

    assert ability.can? :update, posts(:zach_post_1)
    assert ability.cannot? :update, posts(:dave_post_1)
  end

  test "associated mentions are destroyed with their post" do
    p = posts(:zach_post_1)
    mention = p.mentions.create(user: users(:full_hacker_schooler), mentioned_by: p.author)

    p.destroy
    assert mention.destroyed?
  end

  test "marking an earlier post as visited doesn't regress a user's visited status" do
    user = users(:hacker_schooler_1)
    p1 = posts(:first_in_thread_created_by_full_hacker_schooler)
    p2 = posts(:second_in_thread_created_by_full_hacker_schooler)

    p2.mark_as_visited(user)

    assert_equal p2.post_number, VisitedStatus.where(user: user, thread: p2.thread).first.last_post_number_read

    p1.mark_as_visited(user)

    assert_equal p2.post_number, VisitedStatus.where(user: user, thread: p2.thread).first.last_post_number_read
  end

  test "marking a new post as visited simultaneously does not result in multiple visited statuses" do
    user = users(:full_hacker_schooler_2)

    thread = discussion_threads(:created_by_full_hacker_schooler)
    post = thread.posts.create(author: users(:full_hacker_schooler), body: "...")

    5.times.map do
      Thread.new do
        sleep 0.1
        begin
          post.mark_as_visited(user)
        rescue; end
        ActiveRecord::Base.clear_active_connections!
      end
    end.map(&:join)

    assert_equal 1, VisitedStatus.where(user: user, thread: thread).count
  end
end
