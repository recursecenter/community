class Api::SubforumGroupsController < Api::ApiController
  def index
    @subforum_groups = SubforumGroup.all.includes(:subforums)
  end
end
