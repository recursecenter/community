require 'test_helper'

class Api::SubforumGroupsControllerTest < ActionController::TestCase
  test "a logged in user can access subforum groups" do
    login(users(:zach))
    get :index, format: :json
    assert_response :success
  end

  test "a guest cannot access subforum groups" do
    get :index, format: :json
    assert_response :forbidden
  end
end
