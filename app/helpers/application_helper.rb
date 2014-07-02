module ApplicationHelper
  def post_url(slug:, thread_id:, id:)
    thread_url(slug: slug, id: thread_id)
  end
end
