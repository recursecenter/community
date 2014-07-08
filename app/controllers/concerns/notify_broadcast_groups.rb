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
      message = NotificationMailer.broadcast_email(broadcast_users, post, groups)

      m = Mail.new do
        content_type "multipart/mailgun-variables"
        from NotificationMailer::DEFAULT_FROM
      end

      recipient_variables = broadcast_users.reduce({}) do |h, user|
        h[user.email] = {}
        h
      end

      json = Mail::Part.new do
        content_type "application/json"
        content_transfer_encoding "base64"
        body Base64.encode64(JSON.dump(recipient_variables))
      end

      message_part = Mail::Part.new do
        content_type "message/rfc822"
        body message.to_s
      end

      m.add_part(json)
      m.add_part(message_part)

      m.deliver
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
