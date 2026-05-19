require 'test_helper'

class SubforumGroupTest < ActiveSupport::TestCase
  test "includes_subforums_for_user filters subforums by required roles" do
    user = users(:hacker_schooler_1)
    user.roles = [roles(:everyone)]

    group = subforum_groups(:one)

    accessible = subforums(:welcome)
    accessible.update!(subforum_group: group, required_role_ids: [roles(:everyone).id])

    restricted = subforums(:programming)
    restricted.update!(subforum_group: group, required_role_ids: [roles(:full_hacker_schooler).id])

    visible = SubforumGroup.includes_subforums_for_user(user).flat_map(&:subforums)

    assert_includes visible, accessible
    refute_includes visible, restricted
  end
end
