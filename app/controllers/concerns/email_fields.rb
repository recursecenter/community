module EmailFields
  extend ActiveSupport::Concern

  def from_field(user)
    %{"#{user.name}" <#{user.email}>}
  end

  def subject_field(thread)
    "[Community - #{thread.subforum.name}] #{thread.title}"
  end

  def reply_to_community(reply_info)
    "reply-#{reply_info}@mail.community.hackerschool.com"
  end

  def list_post_field(reply_info)
    "Community <#{reply_to_community(reply_info)}>"
  end

  def list_id_field
    "<community.hackerschool.com>"
  end
end
