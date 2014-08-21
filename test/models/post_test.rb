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
    user = users(:full_hacker_schooler)
    p = discussion_threads(:created_by_full_hacker_schooler).
      posts.create(author: user, body: "post body")
    mention = p.mentions.create(user: user, mentioned_by: user)

    p.destroy

    assert mention.destroyed?
  end
end
