require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "users can have many roles" do
    zach = users(:zach)
    zach.roles = [roles(:everyone), roles(:full_hacker_schooler), roles(:admin)]

    hacker_schooler_1 = users(:hacker_schooler_1)
    hacker_schooler_1.roles = [roles(:everyone)]

    assert hacker_schooler_1.satisfies_roles?(roles(:everyone))
    assert_not hacker_schooler_1.satisfies_roles?(roles(:admin))

    full_hacker_schooler_and_admin = Role.where(name: ["admin", "full_hacker_schooler"])

    assert zach.satisfies_roles?(*full_hacker_schooler_and_admin)
    assert_not hacker_schooler_1.satisfies_roles?(*full_hacker_schooler_and_admin)
    assert hacker_schooler_1.satisfies_roles?(*Role.none)

    assert hacker_schooler_1.satisfies_roles?(roles(:everyone), roles(:everyone))
  end
end
