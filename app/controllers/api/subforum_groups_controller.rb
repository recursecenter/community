class Api::SubforumGroupsController < Api::ApiController
  skip_authorization_check only: [:index]

  def index
    @subforum_groups = SubforumGroupIndexQuery.new(current_user)
  end
end
