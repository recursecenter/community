class WebSocketHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    session = Session.new(env)

    if session.websocket?
      unless session.authenticated?
        raise ActionController::InvalidAuthenticityToken
      end
      unless session.current_user
        return [403, {}, ["Not authorized."]]
      end

      session.hijack!
      pubsub.register(session)

      session.ws.rack_response
    else
      @app.call(env)
    end
  end

private

  # Lazily instantiated to make sure the PubSub instance is created after fork
  def pubsub
    @pubsub ||= PubSub.new
  end

  class Session
    include ActiveSupport::Configurable
    include ActionController::RequestForgeryProtection

    def initialize(env)
      @env = env
      @ws = nil
    end

    def [](k)
      @env["rack.session"][k]
    end

    def ws
      unless @ws
        raise "Cannot access Session#ws until after Session#hijack!"
      end
      @ws
    end

    def hijack!
      @ws ||= Faye::WebSocket.new(@env, nil, ping: 45)
    end

    def websocket?
      Faye::WebSocket.websocket?(@env) && @env["PATH_INFO"] == "/websocket"
    end

    def authenticated?
      @req ||= Rack::Request.new(@env)

      valid_authenticity_token?(self, @req.params["csrf_token"])
    end

    def current_user
      @current_user ||= User.where(id: self["user_id"]).first
    end
  end
end
