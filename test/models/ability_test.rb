require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  test "required roles are checked when present" do
    person = users(:hacker_schooler_1)
    binding.pry
    assert Ability.new(person).can? :read, subforums(:welcome)
    assert Ability.new(person).cannot? :read, subforums(:programming)
  end
end
