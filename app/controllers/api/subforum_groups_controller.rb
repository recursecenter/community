class Api::SubforumGroupsController < Api::ApiController
  load_and_authorize_resource

  def index
    @subforum_groups = @subforum_groups.includes(:subforums)
  end
end
