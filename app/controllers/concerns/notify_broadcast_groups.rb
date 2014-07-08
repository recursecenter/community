module NotifyBroadcastGroups
  extend ActiveSupport::Concern

  def notify_broadcast_groups!(post)
    if broadcast_params[:broadcast_to].present?
      Delayed::Job.enqueue(Broadcast.new(post.id, broadcast_params[:broadcast_to]))
    end
  end

private
  def broadcast_params
    params.permit(broadcast_to: [])
  end

  class Broadcast
    attr_reader :post_id, :group_ids

    def initialize(post_id, group_ids)
      @post_id = post_id
      @group_ids = group_ids
    end

    def perform
      broadcast_users.each do |user|
        NotificationMailer.broadcast_email(user, post, groups)
      end
    end

    private
    def broadcast_users
      GroupMembership.where(group_id: group_ids).
        distinct_by_user_id.
        includes(:user).
        map(&:user)
    end

    def post
      @post ||= Post.find(post_id)
    end

    def groups
      @groups ||= Group.where(id: group_ids)
    end
  end
end
