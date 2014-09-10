module EmailFields
  extend ActiveSupport::Concern

  def reply_to_thread_address(reply_info)
    "Community <reply-#{reply_info}@mail.community.hackerschool.com>"
  end

  def subforum_thread_subject(thread)
    "[Community - #{thread.subforum.name}] #{thread.title}"
  end
end
