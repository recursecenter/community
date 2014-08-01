module EmailFields
  extend ActiveSupport::Concern

  def from_field(name)
    %{"#{name} (via Community)" <bot@mail.community.hackerschool.com>}
  end

  def reply_to_field(reply_info)
    "reply-#{reply_info}@reply.community.hackerschool.com"
  end
end
