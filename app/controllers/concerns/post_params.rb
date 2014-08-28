module PostParams
  extend ActiveSupport::Concern

  def post_params
    broadcast_to = params.permit(broadcast_to: [])[:broadcast_to]
    broadcast_to_subscribers = broadcast_to && !!broadcast_to.delete(Group::Subscribers::ID)
    params.require(:post).permit(:body).
      merge(author: current_user,
            broadcast_groups: Group.where(id: broadcast_to),
            broadcast_to_subscribers: broadcast_to_subscribers)
  end
end
