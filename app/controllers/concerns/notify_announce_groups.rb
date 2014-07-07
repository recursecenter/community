module NotifyAnnounceGroups
  extend ActiveSupport::Concern

  def notify_announce_groups!(post)
    if announce_params[:announce_to].present?
      Delayed::Job.enqueue(Announcement.new(post.id, announce_params[:announce_to]))
    end
  end

private
  def announce_params
    params.permit(announce_to: [])
  end

  class Announcement
    attr_reader :post_id, :group_ids

    def initialize(post_id, group_ids)
      @post_id = post_id
      @group_ids = group_ids
    end

    def perform
      announce_users.each do |user|
        NotificationMailer.delay.announcement_email(user, post, groups)
      end
    end

    private
    def announce_users
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
