class Api::ThreadsController < Api::ApiController
  load_and_authorize_resource :thread, class: 'DiscussionThread'

  include NotifyMentionedUsers
  include NotifyBroadcastGroups

  def show
    @thread.mark_as_visited_for(current_user)
    @autocomplete_users = User.select(:id, :first_name, :last_name).ordered_by_first_name
  end

  def create
    @thread.transaction do
      @thread.save!
      @post = @thread.posts.create!(post_params)
    end
    @autocomplete_users = User.select(:id, :first_name, :last_name).ordered_by_first_name

    notify_mentioned_users!(@post)
    notify_broadcast_groups!(@post)
  end

private
  def create_params
    subforum = Subforum.find(params[:subforum_id])
    params.require(:thread).permit(:title).
      merge(created_by: current_user, subforum: subforum)
  end

  def post_params
    params.require(:post).permit(:body).
      merge(author: current_user,
            broadcast_groups: Group.where(id: params.permit(broadcast_to: [])[:broadcast_to]))
  end
end
