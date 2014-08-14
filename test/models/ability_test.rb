require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  test "required roles are checked when present" do
    admitted = users(:hacker_schooler_1)
    assert Ability.new(admitted).can? :read, subforums(:welcome)
    assert Ability.new(admitted).cannot? :read, subforums(:programming)
  end
end
