module ApplicationHelper
  def markdown(md)
    markdown_renderer = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new,
      autolink: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      lax_spacing: true
    )

    sanitize(markdown_renderer.render(md))
  end
end
