require 'test_helper'

class PostTest < ActiveSupport::TestCase
  test "Users can only edit posts they wrote" do
    posts(:zach_post_1).thread.subforum.required_role_ids = []
    posts(:dave_post_1).thread.subforum.required_role_ids = []

    ability = Ability.new(users(:zach))

    assert ability.can? :update, posts(:zach_post_1)
    assert ability.cannot? :update, posts(:dave_post_1)
  end
end
