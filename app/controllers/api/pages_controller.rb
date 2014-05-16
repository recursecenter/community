class Api::PagesController < Api::ApiController
  def forum_index
    @subforum_groups = SubforumGroup.all.includes(:subforums)
  end
end
