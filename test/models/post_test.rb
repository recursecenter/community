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
end
