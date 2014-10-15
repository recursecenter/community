class Api::SubforumGroupsController < Api::ApiController
  skip_authorization_check only: [:index]

  def index
    @subforum_groups = SubforumGroup.for_user(current_user)
  end
end
