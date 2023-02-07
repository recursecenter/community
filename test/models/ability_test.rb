require 'test_helper'

class AbilityTest < ActiveSupport::TestCase
  test "required roles are checked when present" do
    person = users(:hacker_schooler_1)
    welcome = subforums(:welcome)
    programming = subforums(:programming)

    person.roles = [roles(:everyone)]
    welcome.required_role = roles(:everyone)
    programming.required_role = roles(:full_hacker_schooler)

    assert Ability.new(person).can? :read, subforums(:welcome)
    assert Ability.new(person).cannot? :read, subforums(:programming)
  end
end
