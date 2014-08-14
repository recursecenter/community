require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "users can have many roles" do
    zach = users(:zach)
    hacker_schooler_1 = users(:hacker_schooler_1)

    assert hacker_schooler_1.has_roles?(roles(:admitted))
    assert_not hacker_schooler_1.has_roles?(roles(:faculty))

    attended_and_faculty = Role.where(name: ["faculty", "attended"])

    assert zach.has_roles?(*attended_and_faculty)
    assert_not hacker_schooler_1.has_roles?(*attended_and_faculty)
    assert hacker_schooler_1.has_roles?(*Role.none)

    assert hacker_schooler_1.has_roles?(roles(:admitted), roles(:admitted))
  end
end
