module ApplicationHelper
  def post_url(slug:, thread_id:, id:)
    thread_url(slug: slug, id: thread_id)
  end

  def markdown(md)
    markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true), autolink: true, fenced_code_blocks: true, no_intra_emphasis: true)
    sanitize(markdown_renderer.render(md))
  end
end
