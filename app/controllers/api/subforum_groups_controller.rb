class Api::SubforumGroupsController < Api::ApiController
  def index
    @subforum_groups = SubforumGroup.all
  end
end
