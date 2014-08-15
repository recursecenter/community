class Api::SubforumGroupsController < Api::ApiController
  skip_authorization_check only: [:index]

  def index
    @subforum_groups = SubforumGroup.
      includes_subforums_for_user(current_user).
      order("subforums.id ASC")
  end
end
