require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "users can have many roles" do
    zach = users(:zach)
    hacker_schooler_1 = users(:hacker_schooler_1)

    assert hacker_schooler_1.has_roles?(roles(:everyone))
    assert_not hacker_schooler_1.has_roles?(roles(:admin))

    full_hacker_schooler_and_admin = Role.where(name: ["admin", "full_hacker_schooler"])

    assert zach.has_roles?(*full_hacker_schooler_and_admin)
    assert_not hacker_schooler_1.has_roles?(*full_hacker_schooler_and_admin)
    assert hacker_schooler_1.has_roles?(*Role.none)

    assert hacker_schooler_1.has_roles?(roles(:everyone), roles(:everyone))
  end
end
