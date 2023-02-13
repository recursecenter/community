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
        <code><pre>#{ERB::Util.h(threads)}</pre></code>
      </body>
      </html>
    HTML
  end

  private
    def threads
      Thread.list.map do |t|
        "#{t} - #{t.group == ThreadGroup::Default ? "DEFAULT" : "no"}"
      end.join("\n")
    end
end
