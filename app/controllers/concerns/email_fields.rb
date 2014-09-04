module EmailFields
  extend ActiveSupport::Concern

  def from_field(user)
    %{"#{user.name} (via Community)" <#{user.email}>}
  end

  def subject_field(thread)
    "[Community - #{thread.subforum.name}] #{thread.title}"
  end

  def list_post_field(reply_info)
    "Community <reply-#{reply_info}@mail.community.hackerschool.com>"
  end

  def list_id_field
    "<community.hackerschool.com>"
  end
end
