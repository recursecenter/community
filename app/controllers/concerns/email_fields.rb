module EmailFields
  extend ActiveSupport::Concern

  def from_field(user)
    %{"#{user.name}" <#{user.email}>}
  end

  def reply_to_field(reply_info)
    "Community <reply-#{reply_info}@mail.community.hackerschool.com>"
  end

  def subject_field(thread)
    "[Community - #{thread.subforum.name}] #{thread.title}"
  end
end
