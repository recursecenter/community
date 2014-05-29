class WebsocketHandler
  def initialize(app)
    @web_sockets = ThreadSafe::Array.new

    Thread.new do
      loop do
        sleep 2
        p @web_sockets
      end
    end
  end

  def call(env)
    if Faye::WebSocket.websocket?(env)
      ws = Faye::WebSocket.new(env)

      ws.on :message do |event|
        @web_sockets << event.data
        p @web_sockets
      end

      ws.rack_response
    else
      [200, {}, ["Hello, world!"]]
    end
  end
end

=begin
  def initialize(app)
    @app = app
    @pubsub = PubSub.new
  end

  def call(env)
    if Faye::WebSocket.websocket?(env) && env["PATH_INFO"] == "/websocket"
      ws = Faye::WebSocket.new(env)

      @pubsub.register(ws)

      ws.rack_response
    else
      @app.call(env)
    end
  end

  attr_reader :web_sockets

  def initialize(app)
    @web_sockets = ThreadSafe::Array.new

    Foo.new(self)
  end

  def call(env)
    if Faye::WebSocket.websocket?(env)
      ws = Faye::WebSocket.new(env)

      ws.on :message do |event|
        @web_sockets << event.data
        p @web_sockets
      end

      ws.rack_response
    else
      p self
      [200, {}, ["Hello, world!"]]
    end
  end

end

class Foo
  def initialize(handler)
    Thread.new do
      loop do
        sleep 8
        binding.pry
      end
    end
  end
end
=end
