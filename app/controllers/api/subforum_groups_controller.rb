class Api::SubforumGroupsController < Api::ApiController
  skip_authorization_check :index

  def index
    @subforum_groups = SubforumGroup.
      includes(:subforums).
      references(:subforums).
      where("subforums.required_role_ids <@ '{?}'", current_user.role_ids).
      order("subforums.id ASC")
  end
end
