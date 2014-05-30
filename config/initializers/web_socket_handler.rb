class WebSocketHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    if Faye::WebSocket.websocket?(env) && env["PATH_INFO"] == "/websocket"
      session = Session.new(env)

      verify_token!(Rack::Request.new(env), session)
      unless session.current_user
        return [403, {}, ["Not authorized."]]
      end

      ws = Faye::WebSocket.new(env)

      pubsub.register(ws)

      ws.rack_response
    else
      @app.call(env)
    end
  end

private

  # Lazily instantiated to make sure the PubSub instance is created after fork
  def pubsub
    @pubsub ||= PubSub.new
  end

  def verify_token!(req, session)
    csrf_token = session["_csrf_token"]
    unless csrf_token && csrf_token == req.params["csrf_token"]
      raise ActionController::InvalidAuthenticityToken
    end
  end

  class Session
    def initialize(env)
      @env = env
    end

    def [](k)
      @env["rack.session"][k]
    end

    def current_user
      @current_user ||= User.where(id: self["user_id"]).first
    end
  end
end
