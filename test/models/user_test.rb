require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "users can have specific roles" do
    assert users(:hacker_schooler_1).has_role?(:admitted)
    assert_not users(:hacker_schooler_1).has_role?(:faculty)
  end

  test "users can have many roles" do
    assert users(:zach).has_role?(:faculty)
    assert users(:zach).has_role?(:attended)
    assert users(:zach).has_roles?(:faculty, :attended)
    assert_not users(:hacker_schooler_1).has_roles?(:faculty, :attended)
  end
end
