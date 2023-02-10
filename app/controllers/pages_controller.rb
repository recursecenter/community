class PagesController < ApplicationController
  def nope
    raise 'nope!'
  end

  def threadlist
    render html: <<~HTML.html_safe
      <!doctype html>
      <html>
      <head>
        <meta charset="utf-8">
      </head>
      <body>
        <code><pre>#{ERB::Util.h(Thread.list.join("\n"))}</pre></code>
      </body>
      </html>
    HTML
  end
end
