module EmailFields
  extend ActiveSupport::Concern

  def reply_to_thread_address(reply_info)
    "Community <reply-#{reply_info}@mail.community.hackerschool.com>"
  end

  def list_address(subforum)
    "#{subforum.name.downcase.gsub(/\s+/, '-')}@list.community.hackerschool.com"
  end

  def subforum_thread_subject(thread)
    "[Community - #{thread.subforum.name}] #{thread.title}"
  end
end
