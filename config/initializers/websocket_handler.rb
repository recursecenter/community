class WebsocketHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    if Faye::WebSocket.websocket?(env) && env["PATH_INFO"] == "/websocket"
      ws = Faye::WebSocket.new(env)

      pubsub.register(ws)

      ws.rack_response
    else
      @app.call(env)
    end
  end

  # Lazily instantiated to make sure the PubSub instance is created after fork
  def pubsub
    @pubsub ||= PubSub.new
  end
end
